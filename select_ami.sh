# ami-0fcdcdcc9cf0407ae
aws ec2 describe-images   --owners amazon   --filters "Name=name,Values='Deep Learning OSS*Nvidia*PyTorch*2.6*Ubuntu 22.04*'"   --region us-east-1   --query "Images[*].{ID:ImageId,Name:Name}"   --output table 
