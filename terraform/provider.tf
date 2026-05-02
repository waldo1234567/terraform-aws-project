terraform {
  cloud {
    organization = "test-terraform-waldo"
    workspaces {
      project = "learn-terraforming"
      name = "cover-letter-generator-step-func"
    }
  }
  
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"

}


provider "aws" {
  region = var.aws_region
}