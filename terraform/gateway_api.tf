resource "aws_apigatewayv2_api" "frontend_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [ "*" ] #TODO: Restrict this in production
    allow_methods = [ "GET", "POST","OPTIONS" ]
    allow_headers = [ "content-type" ]
  }
}

#Route 1 GET / upload-url

resource "aws_apigatewayv2_integration" "presigned_integration" {
  api_id = aws_apigatewayv2_api.frontend_api.id
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.presigned_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_upload_url" {
  api_id = aws_apigatewayv2_api.frontend_api.id
  route_key = "GET /upload-url"
  target = "integrations/${aws_apigatewayv2_integration.presigned_integration.id}"
}

resource "aws_lambda_permission" "apigw_presigned" {
    statement_id = "AllowExecutionFromAPIGateway"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.presigned_lambda.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_apigatewayv2_api.frontend_api.execution_arn}/*/*"
}


#Route 2 POST /analyze

resource "aws_iam_role" "apigw_sfn_role" {
    name = "${var.project_name}-apigw-sfn-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action    = "sts:AssumeRole"
            Effect    = "Allow"
            Principal = { Service = "apigateway.amazonaws.com" }
        }]
    })
}

resource "aws_iam_role_policy" "apigw_sfn_policy" {
    name   = "sfn-start-execution"
    role = aws_iam_role.apigw_sfn_role.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action    = "states:StartExecution"
            Effect    = "Allow"
            Resource =  aws_sfn_state_machine.job_orchestrator.arn
        }]
    })
}

resource "aws_apigatewayv2_integration" "sfn_integration" {
  api_id = aws_apigatewayv2_api.frontend_api.id
  integration_type = "AWS_PROXY"
  integration_subtype = "StepFunctions-StartExecution"
  credentials_arn = aws_iam_role.apigw_sfn_role.arn

  request_parameters = {
    "StateMachineArn" = aws_sfn_state_machine.job_orchestrator.arn
    "Input" = "$request.body"
  }
}

resource "aws_apigatewayv2_route" "post_analyze" {
  api_id = aws_apigatewayv2_api.frontend_api.id
  route_key = "POST /analyze"
  target = "integrations/${aws_apigatewayv2_integration.sfn_integration.id}"
}

# Route 3 GET /status/{job_id} - can be polled by frontend to check job status

resource "aws_apigatewayv2_integration" "status_integration" {
  api_id = aws_apigatewayv2_api.frontend_api.id
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.status_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_status" {
  api_id = aws_apigatewayv2_api.frontend_api.id
  route_key = "GET /status"
  target = "integrations/${aws_apigatewayv2_integration.status_integration.id}"
}

resource "aws_lambda_permission" "apigw_status" {
    statement_id = "AllowExecutionFromAPIGatewayStatus"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.status_lambda.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_apigatewayv2_api.frontend_api.execution_arn}/*/*"
}

//

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.frontend_api.id
  name = "$default"
  auto_deploy = true
}

output "api_gateway_endpoint" {
    description = "base URL for frontend to use"
    value = aws_apigatewayv2_api.frontend_api.api_endpoint
}

