# ============================================================
# Module: kinesis_stream
# Stream de eventos online. Dimensionado pra POC (1 shard),
# com alarme de iterator age pra sinalizar quando escalar.
# ============================================================

resource "aws_kinesis_stream" "online_events" {
  name             = "${var.domain_name}-online-events-${var.environment}"
  retention_period = var.retention_hours

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  shard_count = var.shard_count

  tags = {
    Domain      = var.domain_name
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "iterator_age" {
  alarm_name          = "${var.domain_name}-kinesis-high-iterator-age-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 3
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 300
  statistic           = "Maximum"
  threshold           = 60000 # 60s = sinal de que precisa mais shards
  alarm_description   = "Kinesis stream ${aws_kinesis_stream.online_events.name} está com lag - considere aumentar shard_count"
  alarm_actions       = var.alarm_sns_topic_arn == "" ? [] : [var.alarm_sns_topic_arn]

  dimensions = {
    StreamName = aws_kinesis_stream.online_events.name
  }
}
