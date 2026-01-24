variable "vpc_id" {
  description = "VPC ID"
}

variable "subnet_ids" {
  description = "Subnets for ALB and EC2"
  type        = list(string)
}

variable "my_ip" {
  description = "Your IP for SSH"
}

variable "log_bucket_name" {
  description = "S3 bucket name for ALB logs"
  type        = string
}