#!/bin/bash

set -e  # Exit on error

# Run terraform
cd terraform
terraform init
terraform apply -auto-approve

# Get the most recent instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
    --region us-west-2 \
    --filters "Name=tag:Name,Values=carla-rl" "Name=instance-state-name,Values=pending,running" \
    --query 'Reservations[].Instances | [0][0].InstanceId' \
    --output text)

if [ -z "$INSTANCE_ID" ]; then
    echo "No running instance found"
    exit 1
fi

echo "Found instance: $INSTANCE_ID"

# Wait for instance to be fully running
aws ec2 wait instance-running --region us-west-2 --instance-ids $INSTANCE_ID
echo "Instance is running"

# Generate AMI name with timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
AMI_NAME="carla-rl-base-${TIMESTAMP}"

# Create AMI
echo "Creating AMI $AMI_NAME..."
AMI_ID=$(aws ec2 create-image \
    --region us-west-2 \
    --instance-id $INSTANCE_ID \
    --name $AMI_NAME \
    --description "CARLA RL base image with pre-pulled Docker images" \
    --output text)

if [ -z "$AMI_ID" ]; then
    echo "Failed to create AMI"
    exit 1
fi

echo "Waiting for AMI $AMI_ID to be available..."
aws ec2 wait image-available --region us-west-2 --image-ids $AMI_ID

echo "AMI $AMI_ID is ready"

# Cleanup
aws ec2 terminate-instances --region us-west-2 --instance-ids $INSTANCE_ID

cd .. 