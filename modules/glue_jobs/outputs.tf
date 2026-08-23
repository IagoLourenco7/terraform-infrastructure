output "scripts_bucket_name" {
  description = "Bucket onde o CI/CD do data-lake-batch-pipeline deve enviar os scripts"
  value       = aws_s3_bucket.scripts.id
}

output "job_names" {
  value = {
    extract_rds      = aws_glue_job.extract_rds.name
    extract_api      = aws_glue_job.extract_api.name
    extract_dynamodb = aws_glue_job.extract_dynamodb.name
    bronze_to_silver = aws_glue_job.bronze_to_silver.name
    silver_to_gold   = aws_glue_job.silver_to_gold.name
  }
}
