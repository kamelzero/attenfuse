# AttenFuse: Attention-based Sensor Fusion for Autonomous Driving

> **Note:** The canonical Docker Compose file is at `docker/docker-compose.yml`. Do not use or maintain other compose files elsewhere in the project. All Docker-based workflows should reference this file.

## Prerequisites
- Python 3.8+
- CUDA 11.8+
- CARLA Simulator 0.9.15
- Docker and Docker Compose

## Installation

### Using Docker (Recommended)
1. Clone the repository:
```bash
git clone https://github.com/AttenfusionRL/attenfuse.git
cd attenfuse
```

2. Build and start the containers:
```bash
cd docker
docker compose up -d
```

### Local Installation
1. Clone the repository:
```bash
git clone https://github.com/AttenfusionRL/attenfuse.git
cd attenfuse
```

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
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
├── docker/                # Docker configuration
├── terraform/             # Infrastructure as Code
└── requirements.txt       # Python dependencies
```

## Usage

### Running with Docker
1. Start the containers:
```bash
cd docker
docker compose up -d
```

2. Run the training script:
```bash
docker compose exec attenfuse python src/train_ppo_attention.py
```

### Running Locally
1. Start the CARLA simulator:
```bash
./CarlaUE4.sh -carla-port=2000
```

2. Run the training script:
```bash
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
python -m pytest src/tests/
```

## Docker Configuration
The project uses two Docker containers:
1. CARLA Simulator (carlasim/carla:0.9.14)
2. AttenFuse client (custom image with Python dependencies)

The Docker setup includes:
- GPU support through NVIDIA Container Toolkit
- Volume mounting for code and data
- Network configuration for CARLA communication
- Environment variable configuration

## License
This project is licensed under the MIT License - see the LICENSE file for details.
