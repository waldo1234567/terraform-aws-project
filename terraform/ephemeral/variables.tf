variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "project_name" {
  type    = string
  default = "ai-market-sentinel"
}

variable "alert_email" {
  description = "Email address for Kill Switch"
  type        = string
}

variable "shard_count" {
  description = "Number of shards for the Kinesis stream"
  type        = number
  default     = 1
}

variable "dashboard_bucket_name" {
  description = "The exact bucket name output by the persistent tier"
  type        = string
}

variable "ssm_parameter_name" {
  description = "The exact SSM parameter name output by the persistent tier"
  type        = string
}
