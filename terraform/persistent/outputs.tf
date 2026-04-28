output "dashboard_bucket_name" {
    description = "The Globally Unique name of the dashboard bucket"
    value = aws_s3_bucket.dashboard.bucket
}

output "ssm_parameter_name" {
    description = "The name of the SSM parameter used to track producer start time"
    value = aws_ssm_parameter.producer_start_time.name
}