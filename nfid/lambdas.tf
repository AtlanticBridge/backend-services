resource "aws_iam_role" "nfid_sign_in_lambda_role" {
  name = "nfid_sign_in_lambda_role"

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

resource "aws_iam_role_policy" "nfid_sign_in_lambda_policy" {
  name   = "nfid_sign_in_lambda_policy"
  role   = aws_iam_role.nfid_sign_in_lambda_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
              "${aws_dynamodb_table.nfid_dynamodb.arn}",
              "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
EOF
}

data "archive_file" "nfid_lambda_archive" {
  type        = "zip"
  source_file = "${path.module}/code/nfid_sign_in.py"
  output_path = "${path.module}/code/nfid_sign_in.zip"
}

resource "aws_lambda_function" "nfid_sign_in_lambda" {
  filename         = data.archive_file.nfid_lambda_archive.output_path
  source_code_hash = data.archive_file.nfid_lambda_archive.output_base64sha256
  publish          = true
  function_name    = "nfid_sign_in_lambda"
  role             = aws_iam_role.nfid_sign_in_lambda_role.arn
  handler          = "nfid_sign_in.lambda_handler"
  runtime          = "python3.8"
  timeout          = 15

  environment {
    variables = {
      CLIENT_ID     = var.client_id
      CLIENT_SECRET = var.client_secret
      REDIRECT_URI  = var.redirect_uri
    }
  }
}


/*
  |========================|
  |    --- MINT KEY ---    |
  |========================|
*/

resource "aws_iam_role" "request_mint_key_lambda_role" {
  name = "request_mint_key_lambda_role"

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

resource "aws_iam_role_policy" "request_mint_key_lambda_policy" {
  name   = "request_mint_key_lambda_policy"
  role   = aws_iam_role.request_mint_key_lambda_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
              "${aws_dynamodb_table.nfid_dynamodb.arn}",
              "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
EOF
}

data "archive_file" "request_mint_key_archive" {
  type        = "zip"
  source_file = "${path.module}/code/request_mint_key.py"
  output_path = "${path.module}/code/request_mint_key.zip"
}

resource "aws_lambda_function" "request_mint_key_lambda" {
  filename         = data.archive_file.request_mint_key_archive.output_path
  source_code_hash = data.archive_file.request_mint_key_archive.output_base64sha256
  publish          = true
  function_name    = "request_mint_key_lambda"
  role             = aws_iam_role.request_mint_key_lambda_role.arn
  handler          = "request_mint_key.lambda_handler"
  runtime          = "python3.8"
  timeout          = 15

  environment {
    variables = {
      MINT_PRIVATE_KEY     = var.mint_private_key
      INFURA_URL = var.infura_url
      NFID_CONTRACT_ADDRESS  = var.nfid_contract_address
    }
  }
}
