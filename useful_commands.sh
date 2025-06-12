# Spot Instance

# Get list of instances with their state, spot request id, and state transition reason
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=carla-rl" \
    --query 'Reservations[].Instances[].[InstanceId,State.Name,SpotInstanceRequestId,StateTransitionReason]' \
    --output table

# To stop the instance (it will preserve state)
aws ec2 stop-instances --instance-ids i-1234567890abcdef0  # change the instance id

# To start it again
aws ec2 start-instances --instance-ids i-1234567890abcdef0 # change the instance id

# Get the instance's public IP
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=carla-rl" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].PublicIpAddress' \
    --output text

# Then SSH in and watch the cloud-init log
ssh ubuntu@<INSTANCE_IP> 'tail -f /var/log/cloud-init-output.log'

####################
# On Demand Instance

# Get the instance ID and public IP
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=carla-rl" "Name=instance-state-name,Values=pending,running" \
    --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress,State.Name]' \
    --output table

# Once you have the IP, monitor cloud-init in real-time
ssh ubuntu@<INSTANCE_IP> 'tail -f /var/log/cloud-init-output.log'

# Or check cloud-init status
ssh ubuntu@<INSTANCE_IP> 'cloud-init status'

# Check if cloud-init encountered any errors
ssh ubuntu@<INSTANCE_IP> 'sudo cat /var/log/cloud-init.log | grep -i error'