#!/bin/bash

# Update system and install dependencies
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    git

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Clone the project repository
cd /home/ubuntu
git clone https://kamelzero:${github_token}@github.com/kamelzero/attenfuse.git
chown -R ubuntu:ubuntu attenfuse

# Configure AWS credentials from instance profile
mkdir -p /home/ubuntu/.aws
echo "[default]" > /home/ubuntu/.aws/config
echo "region = ${aws_region}" >> /home/ubuntu/.aws/config
chown -R ubuntu:ubuntu /home/ubuntu/.aws

# The following will be replaced by Terraform template_file
echo "BUCKET_NAME=${bucket_name}" > /home/ubuntu/attenfuse/.env

# Set the S3 bucket name in environment
echo "BUCKET_NAME=${bucket_name}" >> /etc/environment
source /etc/environment

# Ensure the environment variable is available to the docker-compose service
echo "export BUCKET_NAME=${bucket_name}" >> /home/ubuntu/.bashrc

# Start the docker services
cd attenfuse/docker
docker-compose up -d
