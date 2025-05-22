provider "aws" {
  region = "us-east-1"
}

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
  template = file("${path.module}/cloud-init.sh")

  vars = {
    bucket_name = aws_s3_bucket.logs.bucket
  }
}

resource "aws_instance" "carla_instance" {
  ami                    = "ami-0fcdcdcc9cf0407ae"  # Deep Learning AMI (Ubuntu 22.04) us-east-1
  instance_type          = "g4dn.xlarge"
  key_name               = aws_key_pair.carla_key.key_name
  security_groups        = [aws_security_group.carla_sg.name]
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "0.50"
    }
  }

  user_data = data.template_file.cloud_init.rendered

  tags = {
    Name    = "carla-rl"
    Project = "carla-rl"
  }

  root_block_device {
    volume_size = 100
  }
}

output "public_ip" {
  value = aws_instance.carla_instance.public_ip
}

# S3 bucket for logs
resource "aws_s3_bucket" "logs" {
  bucket        = "my-carla-logs-bucket"
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
