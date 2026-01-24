output "target_group_arn" {
  value = aws_lb_target_group.asg_target_group.arn
}

output "alb_dns_name" {
  value = aws_lb.asg_application_load_balancer.dns_name
}

output "ec2_sg_id" {
  value = aws_security_group.ec2_sg.id
}