resource "aws_iam_role" "sfn_role" {
  name = "${var.project_name}-sfn-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "sfn_policy" {
  name = "invoke-lambdas"
  role = aws_iam_role.sfn_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.scrape_lambda.arn,
          aws_lambda_function.analyze_lambda.arn,
          aws_lambda_function.format_lambda.arn,
          aws_lambda_function.cache_lambda.arn
        ]
      }
    ]
  })
}


resource "aws_sfn_state_machine" "job_orchestrator" {
    name = "${var.project_name}-orchestrator"
    role_arn = aws_iam_role.sfn_role.arn

    definition = jsonencode({
        Comment = "Job Fit Analyzer Orchestration",
        StartAt = "CheckCache",
        States = {
            CheckCache = {
                Type = "Task",
                Resource = aws_lambda_function.cache_lambda.arn,
                Next = "IsCached"
            },
            IsCached = {
                Type = "Choice",
                Choices = [
                    {
                        Variable = "$.is_cached",
                        BooleanEquals = true,
                        Next = "FormatSuccess"
                    }
                ],
                Default = "ScrapeJob"
            },
            ScrapeJob = {
                Type = "Task",
                Resource = aws_lambda_function.scrape_lambda.arn,
                Next = "LocationFilter"
            },
            LocationFilter = {
                Type = "Choice",
                Choices = [
                    {
                        Variable = "$.location_valid",
                        BooleanEquals = false,
                        Next = "InvalidLocation"
                    }
                ],
                Default = "AnalyzeFit"
            },
            AnalyzeFit = {
                Type = "Task",
                Resource = aws_lambda_function.analyze_lambda.arn,
                Next = "FormatSuccess"
            },
            FormatSuccess = {
                Type = "Task",
                Resource = aws_lambda_function.format_lambda.arn,
                End = true
            },
            InvalidLocation = {
                Type = "Pass",
                Result = {
                    status = "FAILED",
                    message = "The provided job location is not valid."
                },
                End = true
             }
            
        }

    })
}