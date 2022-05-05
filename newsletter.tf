module "newsletter_lambda" {
  source       = "./lambda"
  feature_name = "newsletter"
  lambda_policy_actions = [
    "dynamodb:PutItem",
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents"
  ]
  lambda_policy_resources = [
    "${aws_dynamodb_table.nfid_users.arn}",
    "arn:aws:logs:*:*:*"
  ]
  python_file_name = "newsletter_sign_up"
  lambda_layers    = []
  lambda_env_variables = {
    TABLE_NAME = "aws_dynamodb_table.nfid_users.id"
  }
}
