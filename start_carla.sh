#!/bin/bash

echo "Starting CARLA simulator and client..."

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "Virtual environment not found. Please run setup_environment.sh first."
    exit 1
fi

# Activate the virtual environment
source .venv/bin/activate

echo "Using Python version: $(python --version)"
echo "Python path: $(which python)"

# Start CARLA simulator in the background
echo "Starting CARLA simulator..."
docker run --rm -d \
  --name carla-simulator \
  --gpus all \
  --network host \
  carlasim/carla:0.9.15 \
  /bin/bash -c "SDL_VIDEODRIVER=offscreen ./CarlaUE4.sh -opengl -nosound -RenderOffScreen -benchmark -fps=20 -quality-level=Low"

# Wait for CARLA to start
echo "Waiting for CARLA to start..."
sleep 10

# Check if CARLA is running
if ! docker ps | grep -q "carla-simulator"; then
    echo "❌ CARLA simulator failed to start"
    docker logs carla-simulator
    exit 1
fi

echo "✅ CARLA simulator started successfully"

# Set PYTHONPATH to include CARLA Python API
export PYTHONPATH="${PYTHONPATH}:/home/carla/PythonAPI/carla/dist"

echo "Environment ready for training!"
echo "You can now run your training scripts."
echo ""
echo "To stop CARLA: docker stop carla-simulator" 