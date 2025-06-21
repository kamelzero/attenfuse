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

# Check if Python 3.12 is available in pyenv
if ! pyenv versions | grep -q "3.12"; then
    echo "Python 3.12 not found in pyenv. Installing..."
    pyenv install 3.12.1
fi

# Create virtual environment with Python 3.12 if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment with Python 3.12..."
    # Use pyenv's Python 3.12 to create a regular virtual environment
    ~/.pyenv/versions/3.12.1/bin/python -m venv .venv
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

echo "Setting up CARLA Python API for Python 3.12..."

# Install system dependencies for CARLA build
echo "Installing system dependencies for CARLA build..."
sudo apt update
sudo apt install -y python3.12-dev libpython3.12 cmake build-essential

# Install Python dependencies for CARLA build
echo "Installing Python dependencies for CARLA build..."
pip install numpy pygame

# Try to install CARLA directly from pip first (simpler approach)
echo "Attempting to install CARLA from pip..."
pip install carla==0.10.0

# Test if pip installation worked
if python -c "import carla; print('✅ CARLA installed successfully from pip')" 2>/dev/null; then
    echo "Great! CARLA 0.10.0 installed successfully from pip."
else
    echo "Pip installation failed, trying build from source..."
    
    # Start a temporary CARLA 0.10.0 container to get the source
    echo "Starting temporary CARLA 0.10.0 container to extract source..."
    docker run --rm -d \
      --name temp-carla \
      --gpus all \
      --network host \
      carlasim/carla:0.10.0 \
      sleep 60

    sleep 5

    # Copy the CARLA source from the container
    echo "Copying CARLA source from container..."
    docker cp temp-carla:/home/carla /tmp/carla-source

    # Clean up temporary container
    docker stop temp-carla

    # Build CARLA Python API for Python 3.12
    echo "Building CARLA Python API for Python 3.12..."
    cd /tmp/carla-source

    # Check if there's a CMakeLists.txt file (new build system)
    if [ -f "CMakeLists.txt" ]; then
        echo "Using cmake build system..."
        mkdir -p build
        cd build
        cmake .. -DPYTHON_VERSION=3.12
        make PythonAPI
    else
        echo "Using make build system..."
        # Force clean rebuild by removing all build artifacts
        echo "Cleaning all build artifacts..."
        rm -rf PythonAPI/carla/dist
        rm -rf PythonAPI/carla/build
        rm -rf build
        rm -rf .build

        # Set environment variables for Python 3.12
        export PYTHON_VERSION=3.12
        export PYTHON_EXECUTABLE=$(which python)

        echo "Building for Python 3.12..."
        echo "Python executable: $PYTHON_EXECUTABLE"
        echo "Python version: $PYTHON_VERSION"

        # Try different make targets
        make PythonAPI PYTHON_VERSION=3.12 || make pythonapi || make python-api
    fi

    # Check if build was successful
    if [ -f "PythonAPI/carla/dist/carla-0.10.0-py3.12-linux-x86_64.egg" ] || [ -f "PythonAPI/carla/dist/carla-0.10.0-cp312-cp312-linux_x86_64.whl" ]; then
        echo "✅ CARLA build successful!"
        
        # Install the rebuilt module
        echo "Installing rebuilt CARLA module..."
        cd /home/ubuntu/attenfuse
        if [ -f "/tmp/carla-source/PythonAPI/carla/dist/carla-0.10.0-py3.12-linux-x86_64.egg" ]; then
            pip install /tmp/carla-source/PythonAPI/carla/dist/carla-0.10.0-py3.12-linux-x86_64.egg
        elif [ -f "/tmp/carla-source/PythonAPI/carla/dist/carla-0.10.0-cp312-cp312-linux_x86_64.whl" ]; then
            pip install /tmp/carla-source/PythonAPI/carla/dist/carla-0.10.0-cp312-cp312-linux_x86_64.whl
        fi
    else
        echo "❌ CARLA build failed. Checking what was built..."
        
        # Check what files were actually created
        echo "Files in dist directory:"
        ls -la PythonAPI/carla/dist/ 2>/dev/null || echo "No dist directory found"
        
        # Try to install whatever was built
        if [ -d "PythonAPI/carla/dist" ]; then
            echo "Trying to install any available egg/wheel files..."
            cd /home/ubuntu/attenfuse
            for file in /tmp/carla-source/PythonAPI/carla/dist/*.egg /tmp/carla-source/PythonAPI/carla/dist/*.whl; do
                if [ -f "$file" ]; then
                    echo "Installing: $file"
                    pip install --no-deps --force-reinstall "$file"
                    break
                fi
            done
        else
            echo "❌ No build artifacts found. Build completely failed."
            cd /home/ubuntu/attenfuse
        fi
    fi

    # Clean up
    rm -rf /tmp/carla-source
fi

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