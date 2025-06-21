#!/bin/bash

echo "Setting up Python environment for AttenFuse..."

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

echo "Installing PyTorch with CUDA 12.4 support (compatible with CUDA 12.8 drivers)..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

echo "Installing CARLA..."
pip install carla

echo "Installing other requirements..."
pip install -r requirements.txt

echo "Testing CARLA installation..."
python -c "import carla; print('✅ CARLA installed successfully')"

echo "Testing PyTorch CUDA installation..."
python -c "import torch; print(f'✅ PyTorch {torch.__version__} installed with CUDA support')"
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
python -c "import torch; print(f'CUDA version: {torch.version.cuda}')"

echo "Environment setup complete!"
echo "To activate: source .venv/bin/activate"
echo "To start CARLA: ./start_carla.sh" 