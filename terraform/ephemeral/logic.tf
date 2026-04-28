# 1. PACKAGE THE PYTHON CODE

data "archive_file" "logic_lambda_zip" {
  type        = "zip"
  source_dir  = abspath("${path.module}/src/lambdas/logic_lambda")
  output_path = "${path.module}/logic_lambda.zip"
}

# 2. THE AI LOGIC LAMBDA

resource "aws_lambda_function" "logic_processor" {
  function_name = "${var.project_name}-logic-processor"
  role          = aws_iam_role.logic_lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  filename         = data.archive_file.logic_lambda_zip.output_path
  source_code_hash = data.archive_file.logic_lambda_zip.output_base64sha256
  environment {
    variables = {
      DASHBOARD_BUCKET = data.aws_s3_bucket.existing_dashboard.bucket
      BEDROCK_MODEL_ID = "anthropic.claude-3-haiku-20240307-v1:0"
    }
  }

  depends_on = [aws_cloudwatch_log_group.logic_lambda_logs]
}

resource "aws_cloudwatch_log_group" "logic_lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-logic-processor"
  retention_in_days = 3
}


resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = aws_kinesis_stream.market_stream.arn
  function_name     = aws_lambda_function.logic_processor.arn
  starting_position = "LATEST"

  batch_size                     = 100
  tumbling_window_in_seconds     = 300
  maximum_retry_attempts         = 2
  bisect_batch_on_function_error = true
}


