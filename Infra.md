
# CARLA RL Dev Setup (Clean Naming)

This setup gives you a clean, modular workflow for running your RL experiments with CARLA.

## Folder Structure

```
carla-project/
├── Dockerfile.base
├── docker-compose.yml
├── requirements.txt
├── launch_training.sh
├── README.md
└── src/
    ├── train.py
    └── your_rl_files.py
```

## How It Works

- `src/` is your source code, mounted inside the container at `/app`
- The image is built from `Dockerfile.base` and named `carla-rl-base`
- The running container is called `carla_rl`
- AWS credentials from the host (`~/.aws`) are made available inside the container (read-only)
- You can edit files in `src/` live using VSCode Remote SSH

## Commands

```bash
docker compose build     # Build the carla-rl-base image
docker compose up        # Run the carla_rl container
```

Make sure `train.py` is in the `src/` folder.
