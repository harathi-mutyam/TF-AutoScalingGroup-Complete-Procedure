variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for EC2 instances"
  type        = list(string)
}

variable "ec2_sg_id" {
  description = "Security Group ID for EC2 instances"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
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

variable "user_data" {
  description = "User data script for EC2 instances"
  type        = string
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for scaling notifications"
  type        = string
}
