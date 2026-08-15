output "owner_role_arn" {
  value = aws_iam_role.domain_owner.arn
}

output "analyst_role_arn" {
  value = aws_iam_role.domain_analyst.arn
}

output "pipeline_role_arn" {
  value = aws_iam_role.pipeline.arn
}
