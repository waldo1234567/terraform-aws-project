variable "aws_region" {
  description = "The AWS region to deploy the infrastructure"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Base name for tagging and resource naming"
  type        = string
  default     = "ai-cover-letter-func"
}


