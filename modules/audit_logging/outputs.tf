output "audit_logs_bucket_name" {
  value = aws_s3_bucket.audit_logs.id
}

output "audit_logs_bucket_arn" {
  value = aws_s3_bucket.audit_logs.arn
}

output "access_requests_bucket_name" {
  value = aws_s3_bucket.access_requests.id
}
