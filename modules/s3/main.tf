
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