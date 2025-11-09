# This file defines our public-facing API, the route, and the API key.

# 1. Create the API Gateway (HTTP API - cheaper and faster)
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-Api"
  protocol_type = "HTTP"
  description   = "API for IoT Access Control"

  tags = {
    Project = var.project_name
  }
}

# 2. Create the Lambda Integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY" # This is the standard type for Lambda
  integration_uri  = var.lambda_invoke_arn
}

# 3. Create the Route (POST /authorize)
resource "aws_apigatewayv2_route" "authorize_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /authorize" # This is our hardware endpoint
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  # We will add authorization later (in Phase 4)
  authorization_type = "NONE"
}

# 4. Create a "Stage" (e.g., 'prod') to deploy the API
resource "aws_apigatewayv2_stage" "prod_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "prod"
  auto_deploy = true # Automatically deploy changes

  tags = {
    Project = var.project_name
  }
}

# 5. Give API Gateway permission to invoke our Lambda function
resource "aws_lambda_permission" "api_gw_permission" {
  statement_id  = "AllowAPIGatewayToInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # This source_arn restricts the permission to our specific API
  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/${aws_apigatewayv2_route.authorize_route.route_key}"
}

# 6. Create the API Key for our hardware
resource "aws_api_key" "hardware_key" {
  name        = "${var.project_name}-HardwareKey"
  description = "API Key for all production hardware"
  enabled     = true

  tags = {
    Project = var.project_name
  }
}

# 7. Create a Usage Plan (to attach the key to the API)
resource "aws_api_gateway_usage_plan" "hardware_plan" {
  name        = "${var.project_name}-HardwarePlan"
  description = "Usage plan for all production hardware"

  api_stages {
    api_id = aws_apigatewayv2_api.http_api.id
    stage  = aws_apigatewayv2_stage.prod_stage.name
  }
}

# 8. Attach the API Key to the Usage Plan
resource "aws_api_gateway_usage_plan_key" "key_attachment" {
  key_id        = aws_api_key.hardware_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.hardware_plan.id
}