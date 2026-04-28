data "aws_s3_bucket" "existing_dashboard" {
  bucket = var.dashboard_bucket_name
}

data "aws_ssm_parameter" "producer_started_at" {
  name = var.ssm_parameter_name
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_kinesis_stream" "market_stream" {
    name = "${var.project_name}-stream"
    shard_count = var.shard_count
    retention_period = 24

    stream_mode_details {
      stream_mode = "PROVISIONED"
    }
}

resource "aws_s3_bucket" "data_lake"{
    bucket = "${var.project_name}-data-lake-${random_id.bucket_suffix.hex}"
    force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "data_lake_pab" {
    bucket = aws_s3_bucket.data_lake.id

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}
