#!/bin/bash

echo "Setting up Python environment for AttenFuse..."

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

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

# Install CARLA using --find-links pointing to the directory
echo "Installing CARLA from pre-built wheel..."
pip install --find-links=/tmp/carla-dist carla

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
echo "To activate: source .venv/bin/activate"
echo "To start CARLA: ./start_carla.sh"
echo ""
echo "Note: CARLA is set up via PYTHONPATH. The start_carla.sh script will handle this automatically." 