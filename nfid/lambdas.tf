resource "null_resource" "nfid_layer_trigger" {
  # triggers = {
  #   build = "${base64sha256(file("${path.module}/code/requirements.txt"))}"
  # }

  triggers = {
    build_number = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "chmod +x ${path.module}/code/build.sh; ${path.module}/code/build.sh"
  }
}

data "archive_file" "nfid_layer_file" {
  type        = "zip"
  source_dir  = "${path.module}/code/dependencies/python"
  output_path = "${path.module}/code/dependencies/python.zip"
}

resource "aws_lambda_layer_version" "nfid_layer" {
  filename            = data.archive_file.nfid_layer_file.output_path
  layer_name          = "nfid_layer"
  compatible_runtimes = ["python3.8"]
  source_code_hash    = data.archive_file.nfid_layer_file.output_base64sha256
}

resource "aws_iam_role" "nfid_sign_in_lambda_role" {
  name = "nfid_sign_up_lambda_role"

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
                "dynamodb:GetItem",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
              "${aws_dynamodb_table.nfid_users.arn}",
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
  layers           = [aws_lambda_layer_version.nfid_layer.arn]

  environment {
    variables = {
      CLIENT_ID     = var.client_id
      CLIENT_SECRET = var.client_secret
      REDIRECT_URI  = var.redirect_uri
      TABLE_NAME    = aws_dynamodb_table.nfid_users.id
      PYTHONPATH    = "/opt"
      JWT_SECRET    = var.jwt_secret
      ID_SECRET     = var.id_secret
    }
  }
}

resource "aws_iam_role" "nfid_refresh_token_lambda_role" {
  name = "nfid_refresh_token_lambda_role"

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

resource "aws_iam_role_policy" "nfid_refresh_token_lambda_policy" {
  name   = "nfid_refresh_token_lambda_policy"
  role   = aws_iam_role.nfid_refresh_token_lambda_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
              "${aws_dynamodb_table.nfid_users.arn}",
              "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
EOF
}

data "archive_file" "nfid_refresh_token_lambda_archive" {
  type        = "zip"
  source_file = "${path.module}/code/nfid_refresh_token.py"
  output_path = "${path.module}/code/nfid_refresh_token.zip"
}

resource "aws_lambda_function" "nfid_refresh_token_lambda" {
  filename         = data.archive_file.nfid_refresh_token_lambda_archive.output_path
  source_code_hash = data.archive_file.nfid_refresh_token_lambda_archive.output_base64sha256
  publish          = true
  function_name    = "nfid_refresh_token_lambda"
  role             = aws_iam_role.nfid_refresh_token_lambda_role.arn
  handler          = "nfid_refresh_token.lambda_handler"
  runtime          = "python3.8"
  timeout          = 15
  layers           = [aws_lambda_layer_version.nfid_layer.arn]

  environment {
    variables = {
      CLIENT_ID     = var.client_id
      CLIENT_SECRET = var.client_secret
      REDIRECT_URI  = var.redirect_uri
      TABLE_NAME    = aws_dynamodb_table.nfid_users.id
      PYTHONPATH    = "/opt"
      JWT_SECRET    = var.jwt_secret
      ID_SECRET     = var.id_secret
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
              "${aws_dynamodb_table.nfid_users.arn}",
              "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
EOF
}

data "template_file" "temp_mint_key" {
  template = "${file("${path.module}/code/request_mint_key.py")}"
}

data "template_file" "abis_AtlanticId" {
  template = "${file("${path.module}/code/abis/AtlanticId.json")}"
}

data "archive_file" "request_mint_key_archive" {
  type        = "zip"
  # source_file = "${path.module}/code/request_mint_key.py"
  # soruce_dir  = "${path.module}/code/request_mint_key"
  output_path = "${path.module}/code/request_mint_key.zip"

  source {
    content  = "${data.template_file.temp_mint_key.rendered}"
    filename = "request_mint_key.py"
  }

  source {
    content  = "${data.template_file.abis_AtlanticId.rendered}"
    filename = "abis/AtlanticId.json"
  }
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
  layers           = [aws_lambda_layer_version.nfid_layer.arn]

  environment {
    variables = {
      MINT_PRIVATE_KEY      = var.mint_private_key
      INFURA_URL            = var.infura_url
      NFID_CONTRACT_ADDRESS = var.nfid_contract_address
      PYTHONPATH            = "/opt"
    }
  }
}

