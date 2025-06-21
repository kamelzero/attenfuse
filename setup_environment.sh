#!/bin/bash

echo "Setting up Python environment for AttenFuse..."

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

echo "Installing PyTorch with CUDA support..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

echo "Installing CARLA..."
pip install carla

echo "Installing other requirements..."
pip install -r requirements.txt

echo "Testing CARLA installation..."
python -c "import carla; print('✅ CARLA installed successfully')"

echo "Environment setup complete!"
echo "To activate: source .venv/bin/activate"
echo "To start CARLA: ./start_carla.sh" 