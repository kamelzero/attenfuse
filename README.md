# AttenFuse: Attention-based Sensor Fusion for Autonomous Driving

A client for autonomous driving sensor fusion using the CARLA simulator.

## Setup

This project uses CARLA simulator running in Docker with the client running on the host system.

### Prerequisites

- Ubuntu 20.04+ with Docker and NVIDIA drivers installed
- CUDA 12.8 drivers (compatible with CUDA 12.4 runtime)
- At least 8GB RAM and 4GB VRAM

### Quick Start

1. **Setup the environment:**
   ```bash
   chmod +x setup_environment.sh
   ./setup_environment.sh
   ```

   This script will:
   - Install pyenv and Python 3.7.17 (required for CARLA compatibility)
   - Create a virtual environment (`.venv`) using Python 3.7.17
   - Install PyTorch with CUDA 12.4 support
   - Install other dependencies from `requirements.txt`
   - Install CARLA Python API from the simulator container

2. **Start CARLA simulator:**
   ```bash
   chmod +x start_carla.sh
   ./start_carla.sh
   ```

3. **Activate the environment and run training:**
   ```bash
   source .venv/bin/activate
   python src/train_ppo_attention.py
   ```

### Troubleshooting

**CARLA container fails to start:**
- Check GPU availability: `nvidia-smi`
- Check Docker GPU support: `docker run --rm --gpus all nvidia/cuda:12.4-base-ubuntu20.04 nvidia-smi`
- Check system resources: `free -h` and `df -h`

**Python import errors:**
- Ensure you're using Python 3.7: `python --version`
- Activate the virtual environment: `source .venv/bin/activate`
- Check CARLA installation: `python -c "import carla; print('OK')"`

**CUDA errors:**
- Verify CUDA drivers: `nvidia-smi`
- Check PyTorch CUDA support: `python -c "import torch; print(torch.cuda.is_available())"`

## Project Structure
```
attenfuse/
├── src/                    # Source code
│   ├── models/            # Neural network models
│   ├── environments/      # CARLA environment wrappers
│   ├── utils/             # Utility functions
│   └── tests/             # Test files
├── docker/                # Docker configuration (for CARLA simulator only)
├── terraform/             # Infrastructure as Code
├── setup_environment.sh   # Environment setup script
├── start_carla.sh         # CARLA startup script
└── requirements.txt       # Python dependencies
```

## Usage

### Starting CARLA Simulator
1. Start the CARLA simulator:
```bash
chmod +x start_carla.sh
./start_carla.sh
```

This script will:
- Pull and start the CARLA 0.9.15 simulator in a Docker container
- Wait for CARLA to initialize
- Test the connection
- Provide instructions for running training

### Running Training
1. Activate the virtual environment:
```bash
source .venv/bin/activate
```

2. Run the training script:
```bash
python src/train_ppo_attention.py
```

### Alternative: Manual CARLA Startup
If you prefer to start CARLA manually:
```bash
# Start CARLA simulator
docker run --rm -d \
  --name carla-simulator \
  --gpus all \
  --network host \
  carlasim/carla:0.9.15 \
  ./CarlaUE4.sh -RenderOffScreen -nosound

# Wait for CARLA to start, then run training
source .venv/bin/activate
python src/train_ppo_attention.py
```

## Training
The project uses PPO (Proximal Policy Optimization) with attention mechanisms for training. The training process includes:

1. Environment setup with CARLA simulator
2. Sensor data collection (camera, lidar)
3. Attention-based fusion of sensor data
4. PPO training with custom reward functions

### Custom Reward Functions
The environment supports configurable reward functions through the `RewardConfig` class. You can modify the reward structure by adjusting the weights and parameters in the configuration.

Example reward configuration:
```python
reward_config = RewardConfig(
    collision_weight=-1.0,
    speed_weight=0.1,
    lane_weight=0.5,
    distance_weight=0.3
)
```

## Testing
Run the test suite:
```bash
source .venv/bin/activate
python -m pytest src/tests/
```

## Architecture
This project uses a hybrid approach:
- **CARLA Simulator**: Runs in Docker container for GPU access and isolation
- **Training Client**: Runs on host for simplicity and performance
- **Communication**: Via localhost:2000

### Benefits of This Approach
- **Simpler setup**: No complex container networking
- **Better performance**: Direct access to host resources
- **Easier debugging**: Run Python scripts directly
- **Flexible development**: Easy to modify and test code
- **Minimal disk usage**: Only pull CARLA image when needed

## Docker Configuration
The project uses a single Docker container for CARLA:
- **CARLA Simulator**: `carlasim/carla:0.9.15` with GPU support
- **Network**: Host networking for direct access
- **GPU**: Full GPU access for rendering

## Troubleshooting

### CARLA Connection Issues
If CARLA fails to start or connect:
```bash
# Check if CARLA is running
docker ps | grep carla

# Check CARLA logs
docker logs carla-simulator

# Restart CARLA
docker stop carla-simulator
./start_carla.sh
```

### Python Import Issues
If you get import errors:
```bash
# Make sure virtual environment is activated
source .venv/bin/activate

# Reinstall dependencies
./setup_environment.sh
```

### Disk Space Issues
To free up disk space:
```bash
# Remove unused Docker images
docker image prune -a -f

# Remove build cache
docker builder prune -a -f
```

## License
This project is licensed under the MIT License - see the LICENSE file for details.
