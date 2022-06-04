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
    # module.nfid.nfid_users_table_arn,
    "arn:aws:logs:*:*:*"
  ]
  python_file_name = "newsletter_sign_up"
  lambda_layers    = []
  lambda_env_variables = {
    TABLE_NAME = "${module.nfid.nfid_users_table_id}"
  }
}
