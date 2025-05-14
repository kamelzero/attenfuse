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
