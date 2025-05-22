variable "bucket_name" {
  description = "Name of the S3 bucket for CARLA logs"
  type        = string
  default     = "attenfuse-carla-logs-bucket"
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 100
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Ubuntu 22.04 LTS)"
  type        = string
  default     = "ami-0fcdcdcc9cf0407ae"  # Update this for your region
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"  # Optional default value
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}
