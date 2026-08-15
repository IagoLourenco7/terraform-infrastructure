output "lake_bucket_names" {
  value = module.lake_layers.bucket_names
}

output "pipeline_role_arn" {
  value = module.domain_iam.pipeline_role_arn
}

output "kinesis_stream_name" {
  value = module.kinesis_stream.stream_name
}

output "dynamodb_table_name" {
  value = module.dynamodb_online.table_name
}

output "athena_workspaces_bucket" {
  value = module.athena_workspaces.workspaces_bucket_name
}

output "audit_logs_bucket" {
  value = module.audit_logging.audit_logs_bucket_name
}
