resource "null_resource" "nfid_layer_trigger" {
  triggers = {
    build = "${base64sha256(file("${path.module}/code/requirements.txt"))}"
  }

  provisioner "local-exec" {
    command = "chmod +x ${path.module}/code/build.sh; ${path.module}/code/build.sh"
  }
}

data "archive_file" "nfid_layer_file" {
  type        = "zip"
  source_dir  = "${path.module}/code/dependencies/python"
  output_path = "${path.module}/code/dependencies/nfid_layer.zip"
  depends_on = [
  "null_resource.nfid_layer_trigger"
  ]
}

resource "aws_lambda_layer_version" "nfid_layer" {
  filename            = data.archive_file.nfid_layer_file.output_path
  layer_name          = "nfid_layer"
  compatible_runtimes = ["python3.8"]
  license_info        = "${base64sha256(file("${path.module}/code/requirements.txt"))}"
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
    }
  }
}
