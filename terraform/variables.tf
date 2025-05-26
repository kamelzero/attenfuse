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
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-05bf0277baf7fcb3e"  # Update with the ID from step 2
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"  # Optional default value
}
