resource "aws_iam_role" "cache_role" {
  name               = "${var.project_name}-cache-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "cache_policy" {
  name = "dynamodb-read-only"
  role = aws_iam_role.cache_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.job_cache.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "presigned_logs" {
    role = aws_iam_role.presigned_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cache_check_logs" {
    role = aws_iam_role.cache_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "analyze_logs" {
    role = aws_iam_role.analysis_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "format_logs" {
    role = aws_iam_role.formatter_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "scrape_logs" {
    role = aws_iam_role.scraper_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "status_logs" {
    role = aws_iam_role.status_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "presigned_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambdas/presigned"
  output_path = "${path.module}/presigned.zip"
}

data "archive_file" "cache_check_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambdas/cache_check"
  output_path = "${path.module}/cache_check.zip"
}

data "archive_file" "analyze_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambdas/analyze"
  output_path = "${path.module}/analyze.zip"
}

data "archive_file" "format_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambdas/format"
  output_path = "${path.module}/format.zip"
}

data "archive_file" "scrape_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambdas/scrape"
  output_path = "${path.module}/scrape.zip"
}

data "archive_file" "status_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambdas/status"
  output_path = "${path.module}/status.zip"
}



resource "aws_lambda_function" "presigned_lambda" {
  function_name = "${var.project_name}-presigned"
  role = aws_iam_role.presigned_role.arn
  handler = "index.lambda_handler"
  runtime = "python3.12"
  filename = data.archive_file.presigned_zip.output_path
  source_code_hash = data.archive_file.presigned_zip.output_base64sha256
  environment {
    variables = {BUCKET_NAME = aws_s3_bucket.cv_bucket.bucket}
  }
}

resource "aws_lambda_function" "cache_lambda" {
  function_name = "${var.project_name}-cache"
  role = aws_iam_role.cache_role.arn
  handler = "index.lambda_handler"
  runtime = "python3.12"
  filename = data.archive_file.cache_check_zip.output_path
  source_code_hash = data.archive_file.cache_check_zip.output_base64sha256
  environment {
    variables = {CACHE_TABLE = aws_dynamodb_table.job_cache.name}
  }
}

resource "aws_lambda_function" "scrape_lambda" {
  function_name = "${var.project_name}-scrape"
  role = aws_iam_role.scraper_role.arn
  handler = "index.lambda_handler"
  runtime = "python3.12"
  timeout = 15
  filename = data.archive_file.scrape_zip.output_path
  source_code_hash = data.archive_file.scrape_zip.output_base64sha256
}

resource "aws_lambda_function" "analyze_lambda" {
  function_name = "${var.project_name}-analyze"
  role = aws_iam_role.analysis_role.arn
  handler = "index.lambda_handler"
  runtime = "python3.12"
  timeout = 120
  filename = data.archive_file.analyze_zip.output_path
  source_code_hash = data.archive_file.analyze_zip.output_base64sha256
  environment {
    variables = {CV_BUCKET = aws_s3_bucket.cv_bucket.bucket}
  }
}

resource "aws_lambda_function" "format_lambda" {
  function_name = "${var.project_name}-format"
  role = aws_iam_role.formatter_role.arn
  handler = "index.lambda_handler"
  runtime = "python3.12"
  filename = data.archive_file.format_zip.output_path
  source_code_hash = data.archive_file.format_zip.output_base64sha256
  environment {
    variables = {
        REPORTS_BUCKET = aws_s3_bucket.reports_bucket.bucket
        STATE_TABLE = aws_dynamodb_table.job_state.name
        CACHE_TABLE = aws_dynamodb_table.job_cache.name
    }
  }
}

resource "aws_lambda_function" "status_lambda" {
    function_name = "${var.project_name}-status"
    role = aws_iam_role.status_role.arn
    handler = "index.lambda_handler"
    runtime = "python3.12"
    filename = data.archive_file.status_zip.output_path
    source_code_hash = data.archive_file.status_zip.output_base64sha256
    environment {
      variables = {
        STATE_TABLE = aws_dynamodb_table.job_state.name
      }
    }
}