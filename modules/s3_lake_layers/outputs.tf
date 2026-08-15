output "bucket_names" {
  description = "Nomes dos buckets criados por camada"
  value       = { for k, v in aws_s3_bucket.layer : k => v.bucket }
}

output "bucket_arns" {
  description = "ARNs dos buckets por camada"
  value       = { for k, v in aws_s3_bucket.layer : k => v.arn }
}
