#!/bin/bash

# First destroy any existing instance
echo "Destroying any existing instance..."
cd terraform
terraform destroy -auto-approve

# Apply terraform to create instance
echo "Creating new EC2 instance..."
terraform apply -auto-approve

# Get instance ID and IP
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=carla-rl" "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)
INSTANCE_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=carla-rl" "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].PublicIpAddress" \
    --output text)

# Verify we got an instance
if [ -z "$INSTANCE_ID" ]; then
    echo "Error: No instance found"
    exit 1
fi

echo "Instance $INSTANCE_ID is running at $INSTANCE_IP"

# Wait for cloud-init to complete
echo "Waiting for cloud-init to complete..."
sleep 30  # Give instance time to initialize
ssh -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no ubuntu@${INSTANCE_IP} \
    'cloud-init status --wait'

# Generate AMI name with timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
AMI_NAME="carla-rl-base-${TIMESTAMP}"

# Create AMI
echo "Creating AMI..."
AMI_ID=$(aws ec2 create-image \
    --instance-id $INSTANCE_ID \
    --name $AMI_NAME \
    --description "CARLA RL base image with Docker images pre-pulled" \
    --output text)

if [ -z "$AMI_ID" ]; then
    echo "Error: Failed to create AMI"
    exit 1
fi

echo "Waiting for AMI $AMI_ID to be available..."
aws ec2 wait image-available --image-ids $AMI_ID

echo "AMI $AMI_ID is ready"

# Clean up instance
echo "Destroying temporary instance..."
terraform destroy -auto-approve

echo "Done! Update terraform.tfvars with:"
echo "ami_id = \"$AMI_ID\"" 