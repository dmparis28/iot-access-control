# This file defines our public-facing API and the route.

# 1. Create the API Gateway (HTTP API - cheaper and faster)
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-Api"
  protocol_type = "HTTP"
  description   = "API for IoT Access Control"
  # We will use this in Phase 4 for our WAF
  api_key_selection_expression = "$request.header.x-api-key"

  tags = {
    Project = var.project_name
  }
}

# 2. Create the Lambda Integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY" # This is the standard type for Lambda
  integration_uri  = var.lambda_execution_arn 
}

# 3. Create the Route (POST /authorize)
resource "aws_apigatewayv2_route" "authorize_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /authorize" # This is our hardware endpoint
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  
  # api_key_required = true has been removed as it's not supported
  # by HTTP APIs. We will use a WAF in Phase 4.
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
  # This ARN grants permission for any route ("*") on the 'prod' stage
  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/${aws_apigatewayv2_stage.prod_stage.name}/*"
}