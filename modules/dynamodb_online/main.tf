# ============================================================
# Module: dynamodb_online
# Tabela consolidada: recebe carga do batch E do online juntas
# (v1 - sem concorrência entre colunas). On-Demand no POC.
# ============================================================

resource "aws_dynamodb_table" "consolidated" {
  name         = "${var.domain_name}-consolidated-${var.environment}"
  billing_mode = var.billing_mode # PAY_PER_REQUEST no POC

  hash_key  = "entity_id"
  range_key = "record_timestamp"

  attribute {
    name = "entity_id"
    type = "S"
  }

  attribute {
    name = "record_timestamp"
    type = "N"
  }

  # Origem do dado: "batch" ou "online" - útil pra futura
  # arquitetura com concorrência entre colunas
  attribute {
    name = "source"
    type = "S"
  }

  global_secondary_index {
    name            = "source-index"
    hash_key        = "source"
    range_key       = "record_timestamp"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  ttl {
    attribute_name = "expiration_time"
    enabled        = var.enable_ttl
  }

  tags = {
    Domain      = var.domain_name
    Environment = var.environment
  }
}
