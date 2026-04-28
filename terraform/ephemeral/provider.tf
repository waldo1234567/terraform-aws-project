terraform {
  cloud {
    organization = "test-terraform-waldo"
    workspaces {
        project = "aws-terraform-project"
        name = "stream-kinesis-aws"
    }
  }

  required_version = ">=1.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = var.project_name
      ManagedBy = "Terraform"
      Environment = "Ephemeral"
    }
  }
  
}


