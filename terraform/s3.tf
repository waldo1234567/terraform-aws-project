resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "cv_bucket" {
    bucket = "${var.project_name}-cvs-${random_id.suffix.hex}"
    force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cv_lifecycle" {
  bucket = aws_s3_bucket.cv_bucket.id

  rule {
    id     = "expire-48h"
    status = "Enabled"
    filter {}
    expiration {
      days = 2
    }
  }
  
}

resource "aws_s3_bucket_cors_configuration" "cv_cors" {
  bucket = aws_s3_bucket.cv_bucket.id

  cors_rule {
    allowed_headers = [ "*" ]
    allowed_methods = ["PUT"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "reports_bucket" {
  bucket = "${var.project_name}-reports-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "reports_lifecycle" {
  bucket = aws_s3_bucket.reports_bucket.id

  rule {
    id     = "expire-48h"
    status = "Enabled"
    filter {}
    expiration {
      days = 2
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "reports_cors" {
  bucket = aws_s3_bucket.reports_bucket.id

  cors_rule {
    allowed_headers = [ "*" ]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

