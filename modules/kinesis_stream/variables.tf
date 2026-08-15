variable "domain_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "shard_count" {
  type        = number
  default     = 1
  description = "POC: 1 shard = ~1000 put records/sec"
}

variable "retention_hours" {
  type        = number
  default     = 24
  description = "POC: retenção mínima pra economizar"
}

variable "alarm_sns_topic_arn" {
  type        = string
  default     = ""
  description = "SNS topic pra alertas de escalação (opcional)"
}
