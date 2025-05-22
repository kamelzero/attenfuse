#!/bin/bash 
aws ec2 describe-instances --filters "Name=tag:Name,Values=carla-rl" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].[InstanceId,LaunchTime,Tags[?Key==`CreatedAt`].Value|[0]]' --output table
