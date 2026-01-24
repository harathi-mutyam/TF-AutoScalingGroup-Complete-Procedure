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