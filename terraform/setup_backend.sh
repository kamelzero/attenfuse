#!/bin/bash

# Set variables
BUCKET_NAME="attenfuse-tfstate-bucket"
DYNAMODB_TABLE="terraform-locks"
REGION="us-east-1"  # Make sure this matches your AWS region

# Create S3 bucket with correct region specification
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    $(if [ "$REGION" != "us-east-1" ]; then echo "--create-bucket-configuration LocationConstraint=$REGION"; fi)

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"

# Create backend.tf file
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "terraform.tfstate"
    region         = "$REGION"
    dynamodb_table = "$DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF

echo "Backend configuration complete!"
