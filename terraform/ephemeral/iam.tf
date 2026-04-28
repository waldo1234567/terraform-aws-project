data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

#Consumer A : Firehose Role

resource "aws_iam_role" "firehose_role" {
  name               = "${var.project_name}-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

data "aws_iam_policy_document" "firehose_policy_doc" {
  statement {
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]
    resources = [aws_kinesis_stream.market_stream.arn]
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.data_lake.arn,
      "${aws_s3_bucket.data_lake.arn}/*"
    ]
  }

  statement {
    actions   = ["logs:PutLogEvents"]
    resources = ["arn:aws:logs:${var.aws_region}:*:log-group:/aws/kinesisfirehose/${var.project_name}-delivery-stream:*"]
  }
}

resource "aws_iam_role_policy" "firehose_policy_attach" {
  name   = "${var.project_name}-firehose-policy"
  role   = aws_iam_role.firehose_role.id
  policy = data.aws_iam_policy_document.firehose_policy_doc.json
}


#Consumer B : Logic Lambda Role 

resource "aws_iam_role" "logic_lambda_role" {
  name               = "${var.project_name}-logic-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "logic_lambda_policy_doc" {
  statement {
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListStreams"
    ]
    resources = [aws_kinesis_stream.market_stream.arn]
  }

  statement {
    actions   = ["s3:PutObject"]
    resources = ["${data.aws_s3_bucket.existing_dashboard.arn}/*"]
  }

  statement {
    actions   = ["bedrock:InvokeModel"]
    resources = ["arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:${var.aws_region}:*:*"]
  }
}

resource "aws_iam_role_policy" "logic_lambda_policy_attach" {
  name   = "${var.project_name}-logic-policy"
  role   = aws_iam_role.logic_lambda_role.id
  policy = data.aws_iam_policy_document.logic_lambda_policy_doc.json
}

# 3. GOVERNANCE: GUARD LAMBDA ROLE

resource "aws_iam_role" "guard_lambda_role" {
  name               = "${var.project_name}-guard-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "guard_lambda_policy_doc" {
  statement {
    actions = [
      "kinesis:DeleteStream",
      "kinesis:DescribeStream"
    ]
    resources = [aws_kinesis_stream.market_stream.arn]
  }

  statement {
    actions   = ["s3:PutObject"]
    resources = ["${data.aws_s3_bucket.existing_dashboard.arn}/*"]
  }

  statement {
    actions   = ["ssm:GetParameter"]
    resources = [data.aws_ssm_parameter.producer_started_at.arn]
  }

  statement {
    actions = ["sns:Publish"]
    resources = ["arn:aws:sns:${var.aws_region}:*:${var.project_name}-alerts"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:${var.aws_region}:*:*"]
  }
}

resource "aws_iam_role_policy" "guard_lambda_policy_attach" {
  name   = "${var.project_name}-guard-policy"
  role   = aws_iam_role.guard_lambda_role.id
  policy = data.aws_iam_policy_document.guard_lambda_policy_doc.json
}
