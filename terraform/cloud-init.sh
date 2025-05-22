#!/bin/bash
sudo apt update -y
sudo apt install -y docker.io docker-compose awscli
sudo usermod -aG docker ubuntu
newgrp docker

# Set the S3 bucket name in environment
echo "BUCKET_NAME=${bucket_name}" >> /etc/environment
source /etc/environment

# Ensure the environment variable is available to the docker-compose service
echo "export BUCKET_NAME=${bucket_name}" >> /home/ubuntu/.bashrc

# Start the docker services
cd /home/ubuntu
docker-compose up -d
