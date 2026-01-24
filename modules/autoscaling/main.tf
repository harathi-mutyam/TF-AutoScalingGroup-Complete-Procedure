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