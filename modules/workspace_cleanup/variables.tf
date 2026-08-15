variable "environment" {
  type = string
}

variable "workspace_bucket_name" {
  type = string
}

variable "workspace_bucket_arn" {
  type = string
}

variable "days_before_archive" {
  type    = number
  default = 90
}

variable "days_before_delete" {
  type    = number
  default = 180
}
