# Atten Fuse - Lightweight Attention Fusion for Policy Learning

## Introduction

AttenFuse is an attention-based sensor fusion framework for autonomous driving. It combines multi-modal inputs (e.g., LiDAR, camera, radar) using a lightweight attention mechanism to produce robust driving policies. The architecture is designed to support extensions such as uncertainty-aware attention and self-supervised auxiliary tasks to enhance policy learning in reinforcement learning settings.
## Installation

```bash
conda create -n attenfuse python=3.13
conda activate attenfuse
pip -r requirements.txt
```

1. Set Up Environment

    Install CARLA (0.9.15):
    https://github.com/carla-simulator/carla/releases/tag/0.9.15

    ```bash
    wget https://tiny.carla.org/carla-0-9-15-linux -O ~/Downloads/carla-0-9-15-linux.tar.gz
    export CARLA_ROOT=$HOME/carla-0-9-15
    mkdir $CARLA_ROOT
    tar -xvzf ~/Downloads/carla-0-9-15-linux.tar.gz -C $CARLA_ROOT
    ```

2. Run the Simulator
```bash
cd $CARLA_ROOT
./CarlaUE4.sh
```
     
3. Install Python API

```bash
cd $CARLA_ROOT/PythonAPI/carla/dist
pip install --find-links=. carla
```

Test that the CARLA module works:

```bash
python -c "import carla; print('CARLA module loaded')"
```

Then try:

```bash
cd $CARLA_ROOT/PythonAPI/examples
python manual_control.py
```

4. Sensor Configuration in CARLA

While CARLA is running (`$CARLA_ROOT/CarlaUE4.sh -RenderOffScreen`), run: `python log_sensors.py` 

## Tips to Optimize Training

For a modest GPU, e.g. RTX 3080M:
    * Use image resolution: 128×128 or 224×224
    * Use batch size: 32 or lower
    * Use CARLA in -RenderOffScreen mode
    * Avoid running CARLA + training + VSCode + browser all at once
    ```bash
    ./CarlaUE4.sh -RenderOffScreen -quality-level=Low
    ```
    Also make sure you are using:
    ```bash
    torch.cuda.is_available() == True
    ```

# CARLA RL Setup

This repository contains the setup for running CARLA with reinforcement learning.

## Infrastructure Setup

1. Configure AWS credentials and region:

```bash
export AWS_DEFAULT_REGION=us-west-2
```

```bash
cd terraform
terraform init
terraform apply
```

## Instance Setup

The following steps are automated in cloud-init.sh:

1. System dependencies:

```bash
sudo apt-get update && sudo apt-get install -y xvfb
sudo mkdir -p /tmp/xdg-runtime-dir
sudo chmod 700 /tmp/xdg-runtime-dir
```

2. GitHub token (automated in create_base_ami.sh):

```bash
# Copy token from us-east-1 to us-west-2
GITHUB_TOKEN=$(aws ssm get-parameter \
--region us-east-1 \
--name "/carla-rl/github-token" \
--with-decryption \
--query "Parameter.Value" \
--output text)
aws ssm put-parameter \
--region us-west-2 \
--name "/carla-rl/github-token" \
--type SecureString \
--value "$GITHUB_TOKEN"
```

## Running CARLA

1. Start CARLA server:

```bash
cd $CARLA_ROOT
./CarlaUE4.sh -RenderOffScreen -quality-level=Low
```

2. Clone the repository and pull Docker images:

```bash
docker run \
--privileged \
--gpus all \
--net=host \
--runtime=nvidia \
carlasim/carla:0.9.14 \
./CarlaUE4.sh -RenderOffScreen -nosound -carla-rpc-port=2000
```

2. In another terminal, test the setup:

```bash
docker-compose run --rm carla-client python3 docker/test_carla.py
```

## Components

- `docker-compose.yml`: Defines CARLA server and client services
- `Dockerfile.base`: Python environment with CARLA client
- `test_carla.py`: Basic connection test
- `test_carla_advanced.py`: Vehicle spawning and autopilot test
- `test_carla_with_images.py`: Camera capture test

## Notes

- CARLA server runs headless with -RenderOffScreen
- Images are saved as carla_image_*.png in project root
- Client uses CARLA Python API version 0.9.15 with server 0.9.14
