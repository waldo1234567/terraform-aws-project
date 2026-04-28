resource "aws_ssm_parameter" "producer_start_time" {
  name        = "/${var.project_name}/producer/started_at"
  description = "Timestamp tracked by Guard Lambda to enforce budget"
  type        = "String"
  value       = "NOT_STARTED"

  lifecycle {
    ignore_changes = [ value ]
  }
}

