resource "aws_iam_role" "lambda_role" {
  name = "${var.feature_name}_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "${var.feature_name}_lambda_policy"
  role   = aws_iam_role.lambda_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ${var.lambda_policy_actions},
            "Resource": ${var.lambda_policy_resources}
        }
    ]
}
EOF
}

data "archive_file" "lambda_archive" {
  type        = "zip"
  source_file = "${path.module}/code/${var.feature_name}.py"
  output_path = "${path.module}/code/${var.feature_name}.zip"
}

resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.lambda_archive.output_path
  source_code_hash = data.archive_file.lambda_archive.output_base64sha256
  publish          = true
  function_name    = "${var.feature_name}_lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "${var.feature_name}.lambda_handler"
  runtime          = "python3.8"
  timeout          = 15
  layers           = var.lambda_layers

  environment {
    variables = var.lambda_env_variables
  }
}
