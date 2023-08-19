output "s3_bucket_arn" {
  value       = aws_s3_bucket.project_terraform_state.arn
  description = "The ARN of the S3 bucket"
}
