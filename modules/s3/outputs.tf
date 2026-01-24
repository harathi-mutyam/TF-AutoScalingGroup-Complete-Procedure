output "bucket_name" {
  description = "The name of the private ALB log bucket"
  value       = aws_s3_bucket.alb_logs.id
}

output "bucket_arn" {
  description = "The ARN of the private ALB log bucket"
  value       = aws_s3_bucket.alb_logs.arn
}