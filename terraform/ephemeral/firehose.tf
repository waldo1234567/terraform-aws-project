resource "aws_kinesis_firehose_delivery_stream" "data_lake_stream" {
  name = "${var.project_name}-delivery-stream"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.market_stream.arn
    role_arn = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.data_lake.arn

    buffering_size = 5
    buffering_interval = 60

    prefix = "raw-data/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
  
    cloudwatch_logging_options {
      enabled = true
      log_group_name = "/aws/kinesisfirehose/${var.project_name}-delivery-stream"
      log_stream_name = "S3Delivery"
    }
  }
}

resource "aws_cloudwatch_log_group" "firehose_logs" {
  name = "/aws/kinesisfirehose/${var.project_name}-delivery-stream"
  retention_in_days = 3
}