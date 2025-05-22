#!/bin/bash
INSTANCE_TAG="carla-rl"
KEY_PATH="~/.ssh/id_ed25519"
USERNAME="ubuntu"

# Get the EC2 instance public IP using AWS CLI and tag filtering
INSTANCE_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=carla-rl" "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].PublicIpAddress" \
    --output text)

if [ -z "$INSTANCE_IP" ]; then
    echo "Error: Could not find running EC2 instance with Project=carla-rl tag"
    exit 1
fi

echo "Found instance at: $INSTANCE_IP"

# SSH into the instance and start the Docker container
ssh -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no ubuntu@${INSTANCE_IP} \
    "cd ~/attenfuse/docker && docker compose up -d"

if [ $? -eq 0 ]; then
    echo "Successfully started training container"
else
    echo "Error starting training container"
    exit 1
fi
