#!/bin/bash

# Default values
INSTANCE_TAG="carla-rl"
KEY_PATH="~/.ssh/id_ed25519"
USERNAME="ubuntu"
ACTION="setup"  # Default action is just setup

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --test)
            ACTION="test"
            shift
            ;;
        --train)
            ACTION="train"
            shift
            ;;
        --setup)
            ACTION="setup"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--setup|--test|--train]"
            exit 1
            ;;
    esac
done

# Get the EC2 instance public IP using AWS CLI and tag filtering
INSTANCE_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=carla-rl" "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].PublicIpAddress" \
    --region us-west-2 \
    --output text)

if [ -z "$INSTANCE_IP" ]; then
    echo "Error: Could not find running EC2 instance with Project=carla-rl tag"
    exit 1
fi

echo "Found instance at: $INSTANCE_IP"

# Wait for cloud-init to complete
echo "Waiting for cloud-init to complete..."
ssh -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no ubuntu@${INSTANCE_IP} \
    'cloud-init status --wait'

if [ $? -ne 0 ]; then
    echo "Error: cloud-init failed to complete"
    exit 1
fi

echo "Cloud-init completed successfully"

# Start the Docker container
echo "Starting Docker container..."
ssh -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no ubuntu@${INSTANCE_IP} \
    "cd ~/attenfuse/docker && docker compose build && docker compose up -d"

if [ $? -ne 0 ]; then
    echo "Error starting Docker container"
    exit 1
fi

echo "Docker container started successfully"

# Run additional actions if requested
case $ACTION in
    "test")
        echo "Running tests..."
        ssh -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no ubuntu@${INSTANCE_IP} \
            "cd ~/attenfuse && python src/test_carla_env_random.py"
        ;;
    "train")
        echo "Starting training..."
        ssh -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no ubuntu@${INSTANCE_IP} \
            "cd ~/attenfuse && python src/train_ppo_attention.py"
        ;;
    "setup")
        echo "Environment setup complete. You can now:"
        echo "1. SSH into the instance: ssh -i ~/.ssh/id_ed25519 ubuntu@${INSTANCE_IP}"
        echo "2. Run tests: python src/test_carla_env_random.py"
        echo "3. Start training: python src/train_ppo_attention.py"
        ;;
esac
