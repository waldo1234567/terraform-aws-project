data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "presigned_role" {
  name               = "${var.project_name}-presigned-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "presigned_policy" {
  name = "s3-put-only"
  role = aws_iam_role.presigned_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.cv_bucket.arn}/uploads/cvs/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role" "scraper_role" {
  name               = "${var.project_name}-scraper-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role" "analysis_role" {
  name               = "${var.project_name}-analysis-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "analysis_policy" {
  name = "bedrock-and-s3"
  role = aws_iam_role.analysis_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.cv_bucket.arn}/*"
      },
      {
        Action   = "bedrock:InvokeModel"
        Effect   = "Allow"
        Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
      }
    ]
  })
}

resource "aws_iam_role" "formatter_role" {
  name               = "${var.project_name}-formatter-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

}

resource "aws_iam_role_policy" "formatter_policy" {
  name = "formatter-policy"
  role = aws_iam_role.formatter_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.reports_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.job_state.arn,
          aws_dynamodb_table.job_cache.arn
        ]
      }
    ]
  })
}


resource "aws_iam_role" "status_role" {
  name               = "${var.project_name}-status-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "status_policy" {
  name = "dynamodb-read-status"
  role = aws_iam_role.status_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:DescribeExecution"
        ]
        Resource = "arn:aws:states:${var.aws_region}:*:execution:${var.project_name}-orchestrator:*"
      }
    ]
  })
}
