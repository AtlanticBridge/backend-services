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
  
  depends_on = ["aws_api_gateway_integration.refresh_login_integration"]
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

resource "aws_api_gateway_resource" "refresh_login_resource" {
  path_part   = "refresh_login"
  parent_id   = aws_api_gateway_rest_api.nfid_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.nfid_api.id
}

resource "aws_api_gateway_method" "refresh_login_cors_method" {
  rest_api_id   = aws_api_gateway_rest_api.nfid_api.id
  resource_id   = aws_api_gateway_resource.refresh_login_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "refresh_login_cors_integration" {
  rest_api_id      = aws_api_gateway_rest_api.nfid_api.id
  resource_id      = aws_api_gateway_resource.refresh_login_resource.id
  http_method      = aws_api_gateway_method.refresh_login_cors_method.http_method
  content_handling = "CONVERT_TO_TEXT"

  type = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "refresh_login_cors_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.nfid_api.id
  resource_id = aws_api_gateway_resource.refresh_login_resource.id
  http_method = aws_api_gateway_method.refresh_login_cors_method.http_method
  status_code = 200

  depends_on = [
    aws_api_gateway_integration.refresh_login_cors_integration,
    aws_api_gateway_method_response.refresh_login_cors_method_response
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Authorization, x-api-key, Content-Type'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS, POST'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method_response" "refresh_login_cors_method_response" {
  rest_api_id = aws_api_gateway_rest_api.nfid_api.id
  resource_id = aws_api_gateway_resource.refresh_login_resource.id
  http_method = aws_api_gateway_method.refresh_login_cors_method.http_method
  status_code = 200

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [
    aws_api_gateway_method.refresh_login_cors_method
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_method" "refresh_login_post_method" {
  rest_api_id      = aws_api_gateway_rest_api.nfid_api.id
  resource_id      = aws_api_gateway_resource.refresh_login_resource.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "refresh_login_integration" {
  rest_api_id             = aws_api_gateway_rest_api.nfid_api.id
  resource_id             = aws_api_gateway_resource.refresh_login_resource.id
  http_method             = aws_api_gateway_method.refresh_login_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.nfid_refresh_token_lambda.invoke_arn
}

resource "aws_lambda_permission" "refresh_login_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nfid_refresh_token_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.nfid_api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_resource" "sign_in_resource" {
  path_part   = "sign_in"
  parent_id   = aws_api_gateway_rest_api.nfid_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.nfid_api.id
}

resource "aws_api_gateway_method" "nfid_cors_method" {
  rest_api_id   = aws_api_gateway_rest_api.nfid_api.id
  resource_id   = aws_api_gateway_resource.sign_in_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "nfid_cors_integration" {
  rest_api_id      = aws_api_gateway_rest_api.nfid_api.id
  resource_id      = aws_api_gateway_resource.sign_in_resource.id
  http_method      = aws_api_gateway_method.nfid_cors_method.http_method
  content_handling = "CONVERT_TO_TEXT"

  type = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "nfid_cors_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.nfid_api.id
  resource_id = aws_api_gateway_resource.sign_in_resource.id
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
  resource_id = aws_api_gateway_resource.sign_in_resource.id
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
  resource_id      = aws_api_gateway_resource.sign_in_resource.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "sign_in_integration" {
  rest_api_id             = aws_api_gateway_rest_api.nfid_api.id
  resource_id             = aws_api_gateway_resource.sign_in_resource.id
  http_method             = aws_api_gateway_method.nfid_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.nfid_sign_in_lambda.invoke_arn
}

resource "aws_lambda_permission" "sign_in_lambda_permission" {
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

/* 
resource "<provider>_<resource_type>" "name" { 
  config options....
  key = "value"
  key2 = "another value"
}


NEED FOR EACH METHOD:

  [1] aws_api_gateway_method
  [2] aws_api_gateway_integration
  [3] aws_api_gateway_deployment
  [4] aws_api_gateway_stage
*/

# resource "aws_api_gateway_rest_api" "mint_api" {
#   name        = "mint_api"
#   description = "API for Mint Key Lambda Function"
#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }
# }

# // ------------------------------------------------------------------------------

# resource "aws_api_getway_resource" "create_mint_key_resource" {
#   parent_id = aws_api_gateway_rest_api.mint_api.root_resource_id
#   parth_part = "mint_api"
#   rest_api_id = aws_api_gateway_rest_api.mint_api.id
# }

# # resource "aws_api_gateway_resource" "create_nfid_resource" {
# #   path_part   = "create_nfid"
# #   parent_id   = aws_api_gateway_rest_api.nfid_api.root_resource_id
# #   rest_api_id = aws_api_gateway_rest_api.nfid_api.id
# # }

# // ------------------------------------------------------------------------------
# #                       ===============================
# #                        --- API GATEWAY METHOD(s) ---
# #                       ===============================

# #                       !!!!!!!!!!!!!!
# #                       --- ITEM 1 ---
# #                       !!!!!!!!!!!!!!
# // MINT Post Method
# resource "aws_api_gateway_method" "mint_post_method" {
#   authorization = "NONE"
#   http_method = "POST"
#   api_key_required = true
#   rest_api_id = aws_api_gateway_rest_api.mint_api.id
#   resource_id = aws_api_getway_resource.mint_key_resource.id
# }

# // MINT CORS Method
# resource "aws_api_gateway_method" "mint_cors_method" {
#   rest_api_id   = aws_api_gateway_rest_api.mint_api.id
#   resource_id   = aws_api_gateway_resource.create_mint_key_resource.id
#   http_method   = "OPTIONS"
#   authorization = "NONE"
# }

# #                       !!!!!!!!!!!!!!
# #                       --- ITEM 2 ---
# #                       !!!!!!!!!!!!!!

# // POST METHOD
# resource "aws_api_gateway_integration" "create_mint_integration" {
#   http_method = aws_api_gateway_method.mint_post_method.http_method
#   resource_id = aws_api_gateway_resource.create_mint_key_resource.id
#   rest_api_id = aws_api_gateway_rest_api.mint_api.id
#   type = "AWS_PROXY"
#   integration_http_method = "POST"
#   uri = aws_lambda_function.requet_mint_key_lambda.invoke_arn
# }

# // CORS RESOURCE
# resource "aws_api_gateway_integration" "create_mint_cors_integration" {
#   http_method = aws_api_gateway_method.mint_cors_method.http_method
#   resource_id = aws_api_gateway_resource.create_mint_key_resource.id
#   rest_api_id = aws_api_gateway_rest_api.mint_api.id
#   content_handling = "CONVERT_TO_TEXT"

#   type = "MOCK"

#   request_templates = {
#     "application/json" = "{ \"statusCode\": 200 }"
#   }
# }

# resource "aws_api_gateway_method_response" "mint_cors_method_response" {
#   http_method = aws_api_gateway_method.mint_cors_method.http_method
#   resource_id = aws_api_gateway_resource.create_mint_key_resource.id
#   rest_api_id = aws_api_gateway_rest_api.mint_api.id
#   status_code = 200

#   response_models = {
#     "application/json" = "Empty"
#   }

#   depends_on = [
#     aws_api_gateway_method.mint_cors_method
#   ]

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = true,
#     "method.response.header.Access-Control-Allow-Methods" = true,
#     "method.response.header.Access-Control-Allow-Origin"  = true
#   }
# }

# resource "aws_api_gateway_integration_response" "mint_cors_integration_response" {
#   http_method = aws_api_gateway_method.mint_cors_method.http_method
#   resource_id = aws_api_gateway_resource.create_mint_key_resource.id
#   rest_api_id = aws_api_gateway_rest_api.mint_api.id
#   status_code = 200

#   depends_on = [
#     aws_api_gateway_integration.create_mint_cors_integration,
#     aws_api_gateway_method_response.mint_cors_method_response
#   ]

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = "'Authorization, x-api-key, Content-Type'",
#     "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS, POST'",
#     "method.response.header.Access-Control-Allow-Origin"  = "'*'"
#   }
# }


# #                       !!!!!!!!!!!!!!
# #                       --- ITEM 3 ---
# #                       !!!!!!!!!!!!!!

# resource "aws_api_gateway_deployment" "v1_mint_deployment" {
#   rest_api_id = aws_api_gateway_rest_api.mint_api.id

#   triggers = {
#     redeployment = sha1(jsonencode(timestamp()))
#   }
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# #                       !!!!!!!!!!!!!!
# #                       --- ITEM 4 ---
# #                       !!!!!!!!!!!!!!

# resource "aws_api_gateway_stage" "v1_mint" {
#   deployment_id = aws_api_gateway_deployment.v1_mint_deployment.id
#   rest_api_id   = aws_api_gateway_rest_api.mint_api.id
#   stage_name    = "V1_mint"
# }

# ## USAGE PLAN ITEMS

# resource "aws_api_gateway_usage_plan" "mint_usage_plan" {
#   name = "mint_usage_plan"

#   api_stages {
#     api_id = aws_api_gateway_rest_api.mint_api.id
#     stage  = aws_api_gateway_stage.v1_mint.stage_name
#   }
# }

# resource "aws_api_gateway_api_key" "mint_api_key" {
#   name = "mint_api_key"
# }

# resource "aws_api_gateway_usage_plan_key" "mint_usage_plan_key" {
#   key_id        = aws_api_gateway_api_key.mint_api_key.id
#   key_type      = "API_KEY"
#   usage_plan_id = aws_api_gateway_usage_plan.mint_usage_plan.id
# }

# // ------------------------------------------------------------------------------
