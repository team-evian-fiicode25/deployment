terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.83.0"
    }
  }
  backend "s3" {
    bucket = "terraform-rideme"
    key    = "terraform.key"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1"
}
