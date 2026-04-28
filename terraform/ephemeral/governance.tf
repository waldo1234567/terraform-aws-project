resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

data "archive_file" "guard_lambda_zip" {
  type        = "zip"
  source_dir  = abspath("${path.module}/src/lambdas/guard_lambda")
  output_path = "${path.module}/guard_lambda.zip"
}

resource "aws_lambda_function" "guard_processor" {
  function_name = "${var.project_name}-guard-processor"
  role          = aws_iam_role.guard_lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  timeout       = 15
  memory_size   = 128

  filename         = data.archive_file.guard_lambda_zip.output_path
  source_code_hash = data.archive_file.guard_lambda_zip.output_base64sha256

  environment {
    variables = {
      STREAM_NAME    = aws_kinesis_stream.market_stream.name
      SSM_PARAM_NAME = data.aws_ssm_parameter.producer_started_at.name
      SNS_TOPIC_ARN  = aws_sns_topic.alerts.arn
    }
  }

  depends_on = [aws_cloudwatch_log_group.guard_lambda_logs]
}


resource "aws_cloudwatch_event_rule" "fifteen_minute_cron" {
  name                = "${var.project_name}-15min-check"
  description         = "Triggers the Guard Lambda every 15 minutes to check Kinesis uptime"
  schedule_expression = "rate(15 minutes)"
}

resource "aws_cloudwatch_log_group" "guard_lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-guard-processor"
  retention_in_days = 3
}

resource "aws_cloudwatch_event_target" "trigger_guard_lambda" {
  rule      = aws_cloudwatch_event_rule.fifteen_minute_cron.name
  target_id = "TriggerGuardLambda"
  arn       = aws_lambda_function.guard_processor.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
    statement_id = "AllowExecutionFromEventBridge"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.guard_processor.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.fifteen_minute_cron.arn
}

