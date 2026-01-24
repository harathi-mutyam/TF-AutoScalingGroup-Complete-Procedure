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



