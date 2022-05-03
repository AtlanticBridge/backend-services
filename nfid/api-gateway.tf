resource "aws_api_gateway_rest_api" "nfid_api" {
  name        = "nfid_api"
  description = "API for NFID project"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "v1_deployment" {
  rest_api_id = aws_api_gateway_rest_api.nfid_api.id

  triggers = {
    redeployment = sha1(jsonencode(timestamp()))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "v1" {
  deployment_id = aws_api_gateway_deployment.v1_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.nfid_api.id
  stage_name    = "V1"
}

resource "aws_api_gateway_usage_plan" "nfid_usage_plan" {
  name = "nfid_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.nfid_api.id
    stage  = aws_api_gateway_stage.v1.stage_name
  }
}

resource "aws_api_gateway_api_key" "nfid_api_key" {
  name = "nfid_api_key"
}

resource "aws_api_gateway_usage_plan_key" "nfid_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.nfid_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.nfid_usage_plan.id
}

resource "aws_api_gateway_resource" "create_nfid_resource" {
  path_part   = "create_nfid"
  parent_id   = aws_api_gateway_rest_api.nfid_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.nfid_api.id
}

resource "aws_api_gateway_method" "nfid_cors_method" {
  rest_api_id   = aws_api_gateway_rest_api.nfid_api.id
  resource_id   = aws_api_gateway_resource.create_nfid_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "nfid_cors_integration" {
  rest_api_id      = aws_api_gateway_rest_api.nfid_api.id
  resource_id      = aws_api_gateway_resource.create_nfid_resource.id
  http_method      = aws_api_gateway_method.nfid_cors_method.http_method
  content_handling = "CONVERT_TO_TEXT"

  type = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "nfid_cors_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.nfid_api.id
  resource_id = aws_api_gateway_resource.create_nfid_resource.id
  http_method = aws_api_gateway_method.nfid_cors_method.http_method
  status_code = 200

  depends_on = [
    aws_api_gateway_integration.nfid_cors_integration,
    aws_api_gateway_method_response.nfid_cors_method_response
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Authorization, x-api-key, Content-Type'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS, POST'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method_response" "nfid_cors_method_response" {
  rest_api_id = aws_api_gateway_rest_api.nfid_api.id
  resource_id = aws_api_gateway_resource.create_nfid_resource.id
  http_method = aws_api_gateway_method.nfid_cors_method.http_method
  status_code = 200

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [
    aws_api_gateway_method.nfid_cors_method
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_method" "nfid_post_method" {
  rest_api_id      = aws_api_gateway_rest_api.nfid_api.id
  resource_id      = aws_api_gateway_resource.create_nfid_resource.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "create_nfid_integration" {
  rest_api_id             = aws_api_gateway_rest_api.nfid_api.id
  resource_id             = aws_api_gateway_resource.create_nfid_resource.id
  http_method             = aws_api_gateway_method.nfid_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.nfid_sign_in_lambda.invoke_arn
}

resource "aws_lambda_permission" "create_nfid_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nfid_sign_in_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.nfid_api.execution_arn}/*/*/*"
}



/*
  |========================|
  |    --- MINT KEY ---    |
  |========================|
*/

resource "aws_api_gateway_integration" "request_mint_key_init_integration" {
  rest_api_id             = aws_api_gateway_rest_api.nfid_api.id
  resource_id             = aws_api_gateway_resource.create_nfid_resource.id
  http_method             = aws_api_gateway_method.nfid_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.request_mint_key_lambda.invoke_arn
}

resource "aws_lambda_permission" "create_request_mint_key_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.request_mint_key_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.nfid_api.execution_arn}/*/*/*"
}