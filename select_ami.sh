aws ec2 describe-images   --owners amazon   --filters "Name=name,Values='Deep Learning OSS*Nvidia*PyTorch*2.6*Ubuntu 22.04*'"   --region us-east-1   --query "Images[*].{ID:ImageId,Name:Name}"   --output table 

# us-east-1
# base ami: ami-0fcdcdcc9cf0407ae
# new ami created from create_base_ami.sh:  
#   ami-0ebecc2f7d90f55a9 (with docker changes), ami-02bc5e41e97797dac (without docker changes)


# us-west-2
# base ami: ami-05bf0277baf7fcb3e
# new ami created from create_base_ami.sh: ami-0f7a19c8624db7738