#!/bin/bash

# Update system and install dependencies
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    git \
    xdg-user-dirs \
    libgl1-mesa-glx \
    xvfb \
    mesa-utils \
    libglu1-mesa \
    libxi6 \
    libxmu6 \
    libxrender1 \
    libxext6 \
    libglvnd0 \
    libglx0 \
    libegl1-mesa

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Get GitHub token
GITHUB_TOKEN=$(aws ssm get-parameter \
    --region ${aws_region} \
    --name "/carla-rl/github-token" \
    --with-decryption \
    --query "Parameter.Value" \
    --output text)

# Clone only if directory doesn't exist
if [ ! -z "$GITHUB_TOKEN" ] && [ ! -d "/home/ubuntu/attenfuse" ]; then
    cd /home/ubuntu
    git clone https://oauth2:$GITHUB_TOKEN@github.com/AttenfusionRL/attenfuse.git
    sudo chown -R ubuntu:ubuntu /home/ubuntu/attenfuse
fi

# Pull Docker images only if directory exists
if [ -d "/home/ubuntu/attenfuse/docker" ]; then
    cd /home/ubuntu/attenfuse/docker
    docker compose pull
fi

# Create directory if it doesn't exist
sudo mkdir -p /home/ubuntu/attenfuse
sudo chown ubuntu:ubuntu /home/ubuntu/attenfuse

# Configure AWS credentials from instance profile
mkdir -p /home/ubuntu/.aws
echo "[default]" > /home/ubuntu/.aws/config
echo "region = ${aws_region}" >> /home/ubuntu/.aws/config
chown -R ubuntu:ubuntu /home/ubuntu/.aws

# Create .env file only if directory exists
if [ -d "/home/ubuntu/attenfuse" ]; then
    echo "BUCKET_NAME=${bucket_name}" > /home/ubuntu/attenfuse/.env
fi

# Set the S3 bucket name in environment
echo "BUCKET_NAME=${bucket_name}" >> /etc/environment
source /etc/environment

# Ensure the environment variable is available to the docker-compose service
echo "export BUCKET_NAME=${bucket_name}" >> /home/ubuntu/.bashrc

# Create /tmp/xdg-runtime-dir with correct permissions
sudo mkdir -p /tmp/xdg-runtime-dir
sudo chmod 700 /tmp/xdg-runtime-dir

# Don't start services here
