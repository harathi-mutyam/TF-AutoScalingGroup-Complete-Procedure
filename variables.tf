variable "region" {
  description = "AWS region for resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "asg_min" {
  description = "Minimum number of instances in ASG"
  type        = number
}

variable "asg_max" {
  description = "Maximum number of instances in ASG"
  type        = number
}

variable "asg_desired" {
  description = "Desired number of instances in ASG"
  type        = number
}

variable "my_ip" {
  description = "Your public IP for SSH access"
  type        = string
}

variable "log_bucket_time" {
  description = "Suffix to make S3 bucket name unique"
  type        = string
}