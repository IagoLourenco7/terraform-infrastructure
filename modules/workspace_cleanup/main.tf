# ============================================================
# Module: workspace_cleanup
# Lambda diária que expurga workspaces do Athena sem acesso
# há muito tempo (arquiva em X dias, deleta em Y dias).
# ============================================================

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/lambda_src.zip"
}

resource "aws_iam_role" "cleanup_lambda" {
  name = "workspace-cleanup-lambda-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cleanup_lambda" {
  name = "cleanup-lambda-policy"
  role = aws_iam_role.cleanup_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [var.workspace_bucket_arn, "${var.workspace_bucket_arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "workspace_cleanup" {
  function_name    = "workspace-cleanup-${var.environment}"
  role              = aws_iam_role.cleanup_lambda.arn
  handler           = "handler.lambda_handler"
  runtime           = "python3.12"
  filename          = data.archive_file.lambda_zip.output_path
  source_code_hash  = data.archive_file.lambda_zip.output_base64sha256
  memory_size       = 256
  timeout           = 300

  environment {
    variables = {
      WORKSPACE_BUCKET     = var.workspace_bucket_name
      DAYS_BEFORE_ARCHIVE  = var.days_before_archive
      DAYS_BEFORE_DELETE   = var.days_before_delete
    }
  }
}

resource "aws_cloudwatch_event_rule" "daily_cleanup" {
  name                = "workspace-cleanup-daily-${var.environment}"
  schedule_expression = "cron(0 2 * * ? *)" # 2h da manhã UTC
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.daily_cleanup.name
  target_id = "WorkspaceCleanupLambda"
  arn       = aws_lambda_function.workspace_cleanup.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.workspace_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_cleanup.arn
}
