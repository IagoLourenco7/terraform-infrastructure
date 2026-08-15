output "workspaces_bucket_name" {
  value = aws_s3_bucket.athena_workspaces.id
}

output "workgroup_names" {
  value = { for k, v in aws_athena_workgroup.user_workgroup : k => v.name }
}
