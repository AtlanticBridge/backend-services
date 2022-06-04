module "newsletter_lambda" {
  source                  = "./lambda"
  feature_name            = "newsletter"
  lambda_policy_actions   = <<EOF
  [
    "dynamodb:PutItem",
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents"
  ]
  EOF 
  lambda_policy_resources = <<EOF
  [
    module.nfid.nfid_users_table_arn,
    "arn:aws:logs:*:*:*"
  ]
  EOF
  python_file_name        = "newsletter_sign_up"
  lambda_layers           = []
  lambda_env_variables = {
    TABLE_NAME = "${module.nfid.nfid_users_table_id}"
  }
}
