# AttenFuse: Attention-based Sensor Fusion for Autonomous Driving

> **Note:** This project uses a simplified setup with CARLA simulator running in Docker and the training client running on the host.

## Prerequisites
- Python 3.8+
- CUDA 11.8+
- Docker and Docker Compose
- NVIDIA GPU with proper drivers

## Installation

### Quick Setup (Recommended)
1. Clone the repository:
```bash
git clone https://github.com/AttenfusionRL/attenfuse.git
cd attenfuse
```

2. Run the setup script to install all dependencies:
```bash
chmod +x setup_environment.sh
./setup_environment.sh
```

This script will:
- Create a Python virtual environment (`.venv`)
- Install PyTorch with CUDA support
- Install CARLA Python client
- Install all other required dependencies

### Manual Installation
1. Create a virtual environment:
```bash
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
```

2. Install PyTorch with CUDA support:
```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

3. Install CARLA:
```bash
pip install carla
```

4. Install other dependencies:
```bash
pip install -r requirements.txt
```

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
├── start_carla.sh         # CARLA simulator startup script
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
