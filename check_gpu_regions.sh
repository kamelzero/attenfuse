#!/bin/bash

# List of regions to check
REGIONS=("us-east-1" "us-east-2" "us-west-1" "us-west-2" "eu-west-1" "eu-west-2")
INSTANCE_TYPE="g4dn.xlarge"

for region in "${REGIONS[@]}"; do
    echo "=== Checking $region ==="
    
    # Check instance availability
    echo "Availability:"
    aws ec2 describe-instance-type-offerings \
        --location-type availability-zone \
        --filters "Name=instance-type,Values=$INSTANCE_TYPE" \
        --region $region \
        --query 'InstanceTypeOfferings[].Location' \
        --output table

    # Check on-demand pricing
    echo "On-Demand Pricing:"
    aws pricing get-products \
        --region us-east-1 \
        --service-code AmazonEC2 \
        --filters "Type=TERM_MATCH,Field=instanceType,Value=$INSTANCE_TYPE" \
        "Type=TERM_MATCH,Field=regionCode,Value=$region" \
        "Type=TERM_MATCH,Field=operatingSystem,Value=Linux" \
        "Type=TERM_MATCH,Field=tenancy,Value=Shared" \
        --query 'PriceList[0]' \
        --output text 2>/dev/null | grep PricePerUnit || echo "Pricing not available"

    # Check current capacity
    echo "Current Capacity:"
    aws ec2 describe-instance-availability \
        --instance-types "$INSTANCE_TYPE" \
        --region "$region" 2>/dev/null || echo "Capacity check not available"

    echo "----------------------------------------"
done
