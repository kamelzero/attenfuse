#!/bin/bash

echo "Setting up Python environment for AttenFuse..."

# Check if pyenv is installed
if ! command -v pyenv &> /dev/null; then
    echo "pyenv not found. Installing pyenv..."
    
    # Install pyenv dependencies
    sudo apt update
    sudo apt install -y make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
    
    # Install pyenv
    curl -fsSL https://pyenv.run | bash
    
    # Add pyenv to shell
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(pyenv init - bash)"' >> ~/.bashrc
    
    # Source the updated bashrc
    source ~/.bashrc
    
    echo "pyenv installed. Please restart your terminal or run: source ~/.bashrc"
    echo "Then run this script again."
    exit 0
fi

# Check if Python 3.10 is available in pyenv
if ! pyenv versions | grep -q "3.10"; then
    echo "Python 3.10 not found in pyenv. Installing..."
    pyenv install 3.10.13
fi

# Create virtual environment with Python 3.10 if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment with Python 3.10..."
    # Use pyenv's Python 3.10 to create a regular virtual environment
    ~/.pyenv/versions/3.10.13/bin/python -m venv .venv
fi

# Activate the virtual environment
source .venv/bin/activate

echo "Using Python version: $(python --version)"
echo "Python path: $(which python)"

echo "Upgrading pip..."
pip install --upgrade pip

echo "Installing PyTorch with CUDA 12.4 support..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

echo "Installing other requirements..."
pip install -r requirements.txt

echo "Setting up CARLA Python API for Python 3.10..."

# Install system dependencies for CARLA build
echo "Installing system dependencies for CARLA build..."
sudo apt update
sudo apt install -y python3.10-dev libpython3.10

# Install Python dependencies for CARLA build
echo "Installing Python dependencies for CARLA build..."
pip install numpy pygame

# Start a temporary CARLA container to get the source
echo "Starting temporary CARLA container to extract source..."
docker run --rm -d \
  --name temp-carla \
  --gpus all \
  --network host \
  carlasim/carla:0.9.15 \
  sleep 60

sleep 5

# Copy the CARLA source from the container
echo "Copying CARLA source from container..."
docker cp temp-carla:/home/carla /tmp/carla-source

# Clean up temporary container
docker stop temp-carla

# Build CARLA Python API for Python 3.10
echo "Building CARLA Python API for Python 3.10..."
cd /tmp/carla-source

# Check if we need to clean first (only if dist directory exists)
if [ -d "PythonAPI/carla/dist" ]; then
    echo "Cleaning previous build..."
    rm -rf PythonAPI/carla/dist
fi

# Build for Python 3.10
echo "Building for Python 3.10..."
make PythonAPI PYTHON_VERSION=3.10

# Check if build was successful
if [ -f "PythonAPI/carla/dist/carla-0.9.15-py3.10-linux-x86_64.egg" ]; then
    echo "✅ CARLA build successful!"
    
    # Install the rebuilt module
    echo "Installing rebuilt CARLA module..."
    cd /home/ubuntu/attenfuse
    pip install /tmp/carla-source/PythonAPI/carla/dist/carla-0.9.15-py3.10-linux-x86_64.egg
else
    echo "❌ CARLA build failed. Trying alternative approach..."
    
    # Try building without specifying Python version (might use system Python)
    echo "Trying build without Python version specification..."
    cd /tmp/carla-source
    make PythonAPI
    
    if [ -f "PythonAPI/carla/dist/carla-0.9.15-py3.10-linux-x86_64.egg" ]; then
        echo "✅ CARLA build successful with default Python!"
        cd /home/ubuntu/attenfuse
        pip install /tmp/carla-source/PythonAPI/carla/dist/carla-0.9.15-py3.10-linux-x86_64.egg
    else
        echo "❌ All build attempts failed. Please check the build logs above."
        echo "You may need to install additional dependencies or use a different approach."
        cd /home/ubuntu/attenfuse
    fi
fi

# Clean up
rm -rf /tmp/carla-source

echo "Testing CARLA installation..."
python -c "import carla; print('✅ CARLA installed successfully')" 2>/dev/null || echo "❌ CARLA installation failed"

echo "Testing PyTorch CUDA installation..."
python -c "import torch; print(f'✅ PyTorch {torch.__version__} installed with CUDA support')"
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
python -c "import torch; print(f'CUDA version: {torch.version.cuda}')"

echo ""
echo "Environment setup complete!"
echo "To activate: source .venv/bin/activate"
echo "To start CARLA: ./start_carla.sh" 