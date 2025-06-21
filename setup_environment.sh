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

# Check if Python 3.7.17 is available in pyenv
if ! pyenv versions | grep -q "3.7.17"; then
    echo "Python 3.7.17 not found in pyenv. Installing..."
    pyenv install 3.7.17
fi

# Create virtual environment with Python 3.7 if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment with Python 3.7.17..."
    pyenv virtualenv 3.7.17 attenfuse-env
    pyenv local attenfuse-env
fi

# Activate the pyenv environment
pyenv activate attenfuse-env

echo "Using Python version: $(python --version)"

echo "Upgrading pip..."
pip install --upgrade pip

echo "Installing PyTorch with CUDA 12.4 support (compatible with CUDA 12.8 drivers)..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

echo "Installing other requirements..."
pip install -r requirements.txt

echo "Setting up CARLA Python API..."
echo "Note: CARLA will be installed from the simulator container's pre-built wheel."

# Start a temporary CARLA container to get the wheel
echo "Starting temporary CARLA container to extract Python API..."
docker run --rm -d \
  --name temp-carla \
  --gpus all \
  --network host \
  carlasim/carla:0.9.15 \
  sleep 60

# Wait for container to be ready
sleep 5

# Copy the CARLA dist directory from the container
echo "Copying CARLA Python API from container..."
docker cp temp-carla:/home/carla/PythonAPI/carla/dist /tmp/carla-dist

# Check what's in the dist directory
echo "Files in dist directory:"
ls -la /tmp/carla-dist/

# Install CARLA using the Python 3.7 wheel
echo "Installing CARLA from pre-built wheel..."
if [ -f "/tmp/carla-dist/carla-0.9.15-cp37-cp37m-manylinux_2_27_x86_64.whl" ]; then
    echo "Found Python 3.7 wheel file, installing..."
    pip install --no-deps --force-reinstall /tmp/carla-dist/carla-0.9.15-cp37-cp37m-manylinux_2_27_x86_64.whl
elif [ -f "/tmp/carla-dist/carla-0.9.15-py3.7-linux-x86_64.egg" ]; then
    echo "Found Python 3.7 egg file, installing..."
    pip install --no-deps --force-reinstall /tmp/carla-dist/carla-0.9.15-py3.7-linux-x86_64.egg
else
    echo "No compatible wheel/egg found, trying find-links approach..."
    pip install --find-links=/tmp/carla-dist --no-deps carla==0.9.15
fi

# Clean up temporary container
docker stop temp-carla

echo "Testing CARLA installation..."
python -c "import carla; print('✅ CARLA installed successfully')"

echo "Testing PyTorch CUDA installation..."
python -c "import torch; print(f'✅ PyTorch {torch.__version__} installed with CUDA support')"
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
python -c "import torch; print(f'CUDA version: {torch.version.cuda}')"

echo ""
echo "Environment setup complete!"
echo "To activate: pyenv activate attenfuse-env"
echo "To start CARLA: ./start_carla.sh" 