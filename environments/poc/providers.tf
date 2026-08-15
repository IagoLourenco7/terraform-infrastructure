terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Backend remoto - ajuste para o seu bucket de state antes do primeiro apply.
  # backend "s3" {
  #   bucket = "SEU-BUCKET-DE-TERRAFORM-STATE"
  #   key    = "poc/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}
