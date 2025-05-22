#!/bin/bash
INSTANCE_TAG="carla-rl"
KEY_PATH="~/.ssh/id_ed25519"
USERNAME="ubuntu"

# Get instance IP
IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=$INSTANCE_TAG" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].PublicIpAddress" --output text)

echo "Connecting to $IP"
ssh -o "StrictHostKeyChecking=no" -i $KEY_PATH $USERNAME@$IP << 'EOF'
  cd ~/carla-project
  docker compose build
  docker compose up -d
EOF
