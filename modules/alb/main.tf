
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