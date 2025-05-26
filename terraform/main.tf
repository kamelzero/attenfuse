provider "aws" {
  region = var.aws_region
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_key_pair" "carla_key" {
  key_name   = "carla_rl_key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_security_group" "carla_sg" {
  name        = "carla_rl_sg"
  description = "Allow SSH"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "cloud_init" {
  template = file("${path.module}/../cloud-init.sh")

  vars = {
    bucket_name = aws_s3_bucket.logs.bucket
    aws_region  = var.aws_region
  }
}

# Create IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "carla_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "CARLA EC2 Role"
  }
}

# Create instance profile to attach the role to EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "carla_ec2_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "carla" {
  ami           = var.ami_id
  key_name               = aws_key_pair.carla_key.key_name
  security_groups        = [aws_security_group.carla_sg.name]
  instance_type = "g4dn.xlarge"  #g5.xlarge" # You might want to make this a variable too
  # instance_market_options {
  #   market_type = "spot"
  #   spot_options {
  #     max_price = "0.50"
  #     instance_interruption_behavior = "terminate"
  #   }
  # }
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  availability_zone    = "${var.aws_region}b"

  user_data = data.template_file.cloud_init.rendered

  tags = {
    Name    = "carla-rl"
    Project = "carla-rl"
    Environment = terraform.workspace
    CreatedAt = timestamp()
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp2"
  }
}

output "public_ip" {
  value = aws_instance.carla.public_ip
}

output "instance_id" {
  value = aws_instance.carla.id
}

# S3 bucket for logs
resource "aws_s3_bucket" "logs" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name = "CARLA Logs"
  }
}

# S3 bucket policy to allow EC2 instance access
resource "aws_iam_role_policy" "s3_access" {
  name = "s3_access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_parameter_store" {
  name = "ec2-parameter-store-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/carla-rl/*",
          "arn:aws:ssm:us-west-2:${data.aws_caller_identity.current.account_id}:parameter/carla-rl/*"
        ]
      }
    ]
  })
}
