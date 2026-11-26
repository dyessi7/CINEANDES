terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Proyecto = var.proyecto
      Entorno  = var.entorno
    }
  }
}
# Segundo proveedor: WAF para CloudFront solo puede crearse en us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Proyecto = var.proyecto
      Entorno  = var.entorno
    }
  }
}
