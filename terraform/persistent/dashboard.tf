resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "dashboard" {
  bucket        = "${var.project_name}-dashboard-${random_id.bucket_suffix.hex}"
  force_destroy = false 
}

resource "aws_s3_bucket_public_access_block" "dashboard_pab" {
  bucket = aws_s3_bucket.dashboard.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "dashboard_policy" {
  bucket = aws_s3_bucket.dashboard.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.dashboard.arn}/*"
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.dashboard_pab]
}

resource "aws_s3_bucket_cors_configuration" "dashboard_cors" {
  bucket = aws_s3_bucket.dashboard.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"] 
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}