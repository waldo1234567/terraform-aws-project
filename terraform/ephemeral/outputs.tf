output "kinesis_stream_arn" {
  value = aws_kinesis_stream.market_stream.arn
}

output "data_lake_bucket_name" {
  value = aws_s3_bucket.data_lake.bucket
}