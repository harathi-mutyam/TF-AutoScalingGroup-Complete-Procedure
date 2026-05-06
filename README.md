Auto scaling Group Project (Using Default VPC)
TF-AutoScalingGroup-Complete-Procedure/
│
├── modules/
│   │
│   ├── alb/
│   │   ├── main.tf            # ALB, Target Group, Listener
│   │   ├── security.tf        # Security Groups (ALB & EC2)
│   │   ├── variables.tf       # vpc_id, subnet_ids, my_ip
│   │   └── outputs.tf         # alb_dns_name, target_group_arn, ec2_sg_id
│   │
│   ├── autoscaling/
│   │   ├── main.tf            # Launch Template, ASG, Scaling Policies
│   │   ├── cloudwatch.tf      # CPU High / Low alarms
│   │   ├── variables.tf       # AMI, instance type, ASG sizes, SNS ARN
│   │   └── outputs.tf         # asg_name
│   │
│   └── s3/
│       ├── main.tf            # S3 bucket + ALB access log policy
│       ├── variables.tf       # bucket_name
│       └── outputs.tf         # bucket_name, bucket_arn
│
├── provider.tf                # AWS provider & region
├── variables.tf               # Global variables
├── terraform.tfvars           # Environment values
├── data.tf                    # Default VPC, subnets, AMI, caller identity
├── main.tf                    # Root module wiring (ALB, ASG, S3)
├── outputs.tf                 # Final ALB DNS output
│
├── sns.tf                     # SNS topic + email subscription
├── keypair.tf                 # EC2 key pair
├── user_data.sh               # Apache + website install script
├── asgkey.pub                 # Public SSH key

👉 Uses AWS Default VPC + Subnets
________________________________________
1️⃣   provider.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

________________________________________
2️⃣ variables.tf (Root)
variable "region" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "asg_min" {
  type = number
}

variable "asg_max" {
  type = number
}

variable "asg_desired" {
  type = number
}

variable "my_ip" {
  type = string
}
variable "log_bucket_time" {
  type = string
}

________________________________________
3️⃣   terraform.tfvars
region        = "us-east-1"
instance_type = "t2.micro"

asg_min     = 1
asg_max     = 3
asg_desired = 2

my_ip = "87.154.160.239/32"

log_bucket_time  = "23012026-1940"
________________________________________
4️⃣   data.tf (Default VPC + Subnets + AMI)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
________________________________________
5️⃣   main.tf (Call Modules)
module "alb" {
  source     = "./modules/alb"
  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids
  my_ip      = var.my_ip

   log_bucket_name = module.s3.bucket_name
}

module "autoscaling" {
  source = "./modules/autoscaling"

  ami_id           = data.aws_ami.amazon_linux.id
  instance_type    = var.instance_type
  subnet_ids       = data.aws_subnets.default.ids
  key_name = aws_key_pair.asg_key.key_name
  ec2_sg_id        = module.alb.ec2_sg_id
  target_group_arn = module.alb.target_group_arn

  asg_min     = var.asg_min
  asg_max     = var.asg_max
  asg_desired = var.asg_desired
  user_data = base64encode(file("user_data.sh"))
  sns_topic_arn   = aws_sns_topic.my_sns_topic.arn

  

}

module "s3" {
  source      = "./modules/s3"
  bucket_name = "my-private-alb-logs-${var.log_bucket_time}"
  
}




keypair.tf

resource "aws_key_pair" "asg_key" {
  key_name   = "asgkey"
  public_key =file("asgkey.pub") # base64encode(file("asgkey.pub"))
}

#generate keyspair using ssh-keygen in git bash terminal of the current project folder
ssh-keygen enter asgkey enter enter


outputs.tf


output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

sns.tf

resource "aws_sns_topic" "my_sns_topic" {
  name = "cpu_alarm_topic"
}

resource "aws_sns_topic_subscription" "my_sns_topic_subscription" {
  topic_arn = aws_sns_topic.my_sns_topic.arn
  protocol  = "email"
  endpoint  = "example@gmail.com"
}

Create user_data.sh

#!/bin/bash
yum update -y
yum install -y httpd wget unzip
systemctl start httpd
systemctl enable httpd
cd /tmp
wget https://www.tooplate.com/zip-templates/2150_living_parallax.zip
unzip -o 2150_living_parallax.zip
cp -r 2150_living_parallax/* /var/www/html/
chown -R apache:apache /var/www/html/




________________________________________
📦 ALB MODULE
modules/alb/variables.tf
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
________________________________________

modules/alb/security.tf
resource "aws_security_group" "alb_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "ec2_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
modules/alb/main.tf
#resource  for application-load-balancer


resource "aws_lb" "asg_application_load_balancer" {
  name               = "asg-application-load-balancer"
  internal = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnet_ids
  enable_cross_zone_load_balancing = true

  # Enabling access logs
 access_logs {
    bucket  = var.log_bucket_name
    enabled = true
  }

  #enable_deletion_protection = false

  tags = {
        Name = "ASG application load balancer"
    }
}

#resource aws_lb_target_group

#This target group will send HTTP traffic to EC2 instances on port 80

resource "aws_lb_target_group" "asg_target_group" {
  name     = "asg-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id   
  target_type = "instance"
  health_check {
      path = "/" #ALB checks if servers are healthy before sending traffic.
      protocol            = "HTTP"
      port                = "traffic-port"
      healthy_threshold   = 2  #Instance is considered healthy after 2 consecutive successful checks.
      unhealthy_threshold = 2  #Instance is considered unhealthy after 2 consecutive successful checks.
  }
   tags = {
        Name = "ASG target group"
    }
}
# A Listener is like a door on your Load Balancer. It listens for incoming traffic and decides where to send it.

resource "aws_lb_listener" "asg_listener" {
  
  load_balancer_arn = aws_lb.asg_application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    
    target_group_arn = aws_lb_target_group.asg_target_group.arn
  }
}
________________________________________
modules/alb/outputs.tf
output "target_group_arn" {
  value = aws_lb_target_group.asg_target_group.arn
}

output "alb_dns_name" {
  value = aws_lb.asg_application_load_balancer.dns_name
}

output "ec2_sg_id" {
  value = aws_security_group.ec2_sg.id
}
________________________________________
📦 AUTOSCALING MODULE
modules/autoscaling/variables.tf
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



________________________________________
modules/autoscaling/main.tf
resource "aws_launch_template" "asg_launch_template" {
  name_prefix = "autoscaling-lt"
  image_id               = var.ami_id  #data.aws_ami.amazon_linux.id    
  instance_type          = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [var.ec2_sg_id]

  user_data              = var.user_data
}

resource "aws_autoscaling_group" "demo_autoscaling_group" {
  min_size         = var.asg_min
  max_size         = var.asg_max
  desired_capacity = var.asg_desired

  vpc_zone_identifier = var.subnet_ids
   # Associate with ALB target group

  target_group_arns  = [var.target_group_arn]

# Specify the launch template defined before
  launch_template {
    id      = aws_launch_template.asg_launch_template.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "autoscaling-instance"
    propagate_at_launch = true
  }

}

# Policy that increases the number of instances by 1 when triggered.(like high cpu)

resource "aws_autoscaling_policy" "increase_ec2" {
    name                   = "increase-ec2"
    scaling_adjustment     = 1
    adjustment_type        = "ChangeInCapacity"
    cooldown               = 300   #Wait 300 seconds before applying another scale action.
    autoscaling_group_name = aws_autoscaling_group.demo_autoscaling_group.name
    policy_type = "SimpleScaling"
    
}

# Automatically decreases EC2 instances by 1 when triggered (like low CPU).

resource "aws_autoscaling_policy" "reduce_ec2" {
    name                   = "reduce-ec2"
    scaling_adjustment     = -1
    adjustment_type        = "ChangeInCapacity"
    cooldown               = 300
    autoscaling_group_name = aws_autoscaling_group.demo_autoscaling_group.name
    policy_type = "SimpleScaling"
}

# Attach the Auto Scaling Group to the ALB target group

resource "aws_autoscaling_attachment" "my_asg_attachment" {
    autoscaling_group_name = aws_autoscaling_group.demo_autoscaling_group.id
    lb_target_group_arn =  var.target_group_arn
    
}
________________________________________
modules/autoscaling/outputs.tf
output "asg_name" {
  value = aws_autoscaling_group.demo_autoscaling_group.name
}

modules/autoscaling/ cloudwatch.tf
resource "aws_cloudwatch_metric_alarm" "increase_ec2_alarm" {
  alarm_name          = "increase-ec2-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Trigger alarm if EC2 CPU utilization goes above 70% for 2 periods"
  insufficient_data_actions = []

  alarm_actions = [
    var.sns_topic_arn,
    aws_autoscaling_policy.increase_ec2.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "reduce_ec2_alarm" {
  alarm_name          = "reduce-ec2-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 40
  alarm_description   = "Trigger alarm if EC2 CPU utilization goes below 40% for 2 periods"
  insufficient_data_actions = []

  alarm_actions = [
    var.sns_topic_arn,
    aws_autoscaling_policy.reduce_ec2.arn
  ]
}
modules/s3/variables.tf
variable "bucket_name" {
  description = "Name of the S3 bucket for ALB logs"
  type        = string
}
modules/s3/data.tf

# Get AWS ELB service account for ALB logging

data "aws_elb_service_account" "elb_logging_account" {}

# Get current AWS account ID

data "aws_caller_identity" "current_account" {}

modules/s3/main.tf


# Create S3 Bucket (PRIVATE)

resource "aws_s3_bucket" "alb_logs" {
  bucket        = var.bucket_name
  force_destroy = true  # enables force deletion of bucket and objects

  tags = {
    Name = "alb-private-access-logs"
  }
}

# Block ALL Public Access 

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket Policy: Allow ONLY ALB to Write Logs

resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowALBToWriteLogs"
        Effect = "Allow"
        Principal = { AWS = data.aws_elb_service_account.elb_logging_account.arn }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.alb_logs.arn}/AWSLogs/${data.aws_caller_identity.current_account.account_id}/*"
        #the bucket policy applies to every log file under the path 
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "AllowALBToCheckACL"
        Effect    = "Allow"
        Principal = { AWS = data.aws_elb_service_account.elb_logging_account.arn }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.alb_logs.arn
      }
    ]
  })
}
modules/s3/outputs.tf

output "bucket_name" {
  description = "The name of the private ALB log bucket"
  value       = aws_s3_bucket.alb_logs.id
}

output "bucket_arn" {
  description = "The ARN of the private ALB log bucket"
  value       = aws_s3_bucket.alb_logs.arn
}


________________________________________
6️⃣   user_data.sh (Root)

#!/bin/bash
yum update -y
yum install -y httpd wget unzip
systemctl start httpd
systemctl enable httpd
cd /tmp
wget https://www.tooplate.com/zip-templates/2150_living_parallax.zip
unzip -o 2150_living_parallax.zip
cp -r 2150_living_parallax/* /var/www/html/
chown -R apache:apache /var/www/html/


________________________________________
7️⃣   outputs.tf (Root)
output "alb_dns_name" {
  value = module.alb.alb_dns_name
}


Project explanation with image 
 

 



1. Project Overview & Objective
The goal of this project is to deploy a High-Availability Web Application using Terraform.
•	Automation: Every resource is defined as code.
•	Scalability: The system grows and shrinks based on traffic (CPU usage).
•	Security: Traffic is restricted via Security Groups, and logs are stored in a private S3 bucket.
________________________________________
2. Phase 1: Preparation (The "Global" Layer)
First, we establish our environment settings and security credentials.
•	Provider Configuration: We tell Terraform to use AWS and specify our target region (us-east-1).
•	Variables & tfvars: We define parameters like instance types and scaling limits so we can change them without editing the core code.
•	SSH Key Pair: We generate a local key (ssh-keygen) and use the keypair.tf to upload the public key to AWS so we can access our instances if needed.
________________________________________
3. Phase 2: Data Discovery (The "Existing" Layer)
Instead of hardcoding IDs, we use Data Sources in data.tf to "look up" existing AWS infrastructure:
•	Default VPC & Subnets: We fetch the IDs of your account's default network setup.
•	Amazon Linux AMI: We dynamically find the latest Amazon Linux 2 image ID so our build is always up-to-date.
________________________________________
4. Phase 3: Modular Infrastructure Build
We break the project into three distinct modules for better organization:
A. S3 Module (Storage & Logging)
•	Creates a private S3 bucket.
•	Bucket Policy: This is critical. We apply a policy that allows the AWS Load Balancer service account to write access logs into this bucket for auditing.
B. ALB Module (The Front Door)
•	Security Groups: We create two. One for the ALB (allows port 80 from everywhere) and one for EC2 (allows port 80 only from the ALB).
•	Application Load Balancer: Distributes incoming traffic across our instances.
•	Target Group & Listener: Defines where traffic should go and performs "Health Checks" to ensure it doesn't send users to a broken server.
C. Auto Scaling Module (The Brains)
•	Launch Template: Defines what to launch (AMI, Instance Type, and the user_data.sh script which installs Apache and the website).
•	Auto Scaling Group (ASG): Defines how many to launch (Min 1, Desired 2, Max 3).
•	Scaling Policies: We use Simple Scaling. If CPU > 70%, add a server; if CPU < 40%, remove one.
________________________________________
5. Phase 4: Monitoring & Notifications
We don't want to check the dashboard manually, so we automate the alerts:
•	CloudWatch Alarms: These watch the average CPU utilization of the ASG.
•	SNS Topic: When an alarm triggers, AWS sends an email notification to the administrator (you) via the Simple Notification Service.
________________________________________
6. Execution & Verification
1.	Initialize: terraform init downloads the AWS provider.
2.	Plan: terraform plan shows exactly what will be built.
3.	Apply: terraform apply builds the entire stack in minutes.
4.	Result: Copy the alb_dns_name from the output, paste it into a browser, and see your live website!
________________________________________
Key Talking Points for your Demo:
•	Self-Healing: Mention that if you manually terminate an instance, the ASG will detect it and automatically launch a new one.
•	Security: Highlight that the EC2 instances are protected; they don't accept traffic from the public internet, only from the Load Balancer.
•	Cost-Efficiency: Explain that Scaling Down during low-traffic periods saves money.
Chat gpt notes







