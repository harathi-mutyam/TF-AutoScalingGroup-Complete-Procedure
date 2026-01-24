# Get AWS ELB service account for ALB logging

data "aws_elb_service_account" "elb_logging_account" {}

# Get current AWS account ID

data "aws_caller_identity" "current_account" {}
