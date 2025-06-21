#!/bin/bash

# Start CARLA simulator in a container
echo "Starting CARLA simulator..."
docker run --rm -d \
  --name carla-simulator \
  --gpus all \
  --network host \
  carlasim/carla:0.9.15 \
  ./CarlaUE4.sh -RenderOffScreen -nosound

echo "CARLA simulator started. Waiting for it to be ready..."
sleep 30

echo "Testing CARLA connection..."
# Activate pyenv environment if available
if command -v pyenv &> /dev/null; then
    pyenv activate attenfuse-env
    echo "Using pyenv environment"
    echo "Python version: $(python --version)"
else
    echo "Warning: pyenv not found."
fi

python3 -c "
import carla
client = carla.Client('localhost', 2000)
client.set_timeout(10.0)
world = client.get_world()
print('✅ CARLA is working!')
print('Map:', world.get_map().name)
"

echo "CARLA is ready! You can now run your training script."
echo "Run: pyenv activate attenfuse-env && python src/train_ppo_attention.py" 