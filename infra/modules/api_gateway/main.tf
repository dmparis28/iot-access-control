# This file defines our public-facing API and routes.
# It now contains TWO types of routes:
# 1. /authorize (Public, for Hardware)
# 2. /admin/* (Secured, for Admin App)

# 1. Create the API Gateway (HTTP API - cheaper and faster)
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-Api"
  protocol_type = "HTTP"
  description   = "API for IoT Access Control"
  
  # This allows our web app to call the API from a browser
  cors_configuration {
    allow_origins = ["*"]
    allow_headers = ["Content-Type", "Authorization"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
  }

  tags = {
    Project = var.project_name
  }
}

# ---
# SECTION 1: HARDWARE ENDPOINT (/authorize)
# ---

# 2. Create the Lambda Integration (for hardware)
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.lambda_execution_arn
}

# 3. Create the Route (POST /authorize)
resource "aws_apigatewayv2_route" "authorize_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /authorize"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  authorization_type = "NONE"
}

# 4. Create a "Stage" (e.g., 'prod') to deploy the API
resource "aws_apigatewayv2_stage" "prod_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "prod"
  auto_deploy = true
  tags = {
    Project = var.project_name
  }
}

# 5. Give API Gateway permission to invoke our *hardware* Lambda function
resource "aws_lambda_permission" "api_gw_permission" {
  statement_id  = "AllowAPIGatewayToInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/${aws_apigatewayv2_stage.prod_stage.name}/*"
}

# ---
# SECTION 2: ADMIN ENDPOINTS (Secured with Cognito)
# ---

# 6. Create the Cognito Authorizer
# This connects our API Gateway to the Cognito User Pool
resource "aws_apigatewayv2_authorizer" "cognito_authorizer" {
  api_id           = aws_apigatewayv2_api.http_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"] # It will look for the 'Bearer' token
  name             = "${var.project_name}-CognitoAuthorizer"

  jwt_configuration {
    # The "audience" is our App Client ID
    audience = [var.admin_auth_user_pool_client_id]
    # The "issuer" is the URL of our Cognito User Pool
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${var.admin_auth_user_pool_id}"
  }

  # This depends on the API existing
  depends_on = [aws_apigatewayv2_api.http_api]
}

# 7. Create the Lambda Integration (for AdminCreateCode)
resource "aws_apigatewayv2_integration" "admin_createcode_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.createCode_lambda_execution_arn
}

# 8. Create the Admin Route (POST /admin/codes)
resource "aws_apigatewayv2_route" "admin_createcode_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /admin/codes" # Our new admin endpoint
  target    = "integrations/${aws_apigatewayv2_integration.admin_createcode_integration.id}"

  # --- THIS IS THE SECURITY ---
  # This route requires a valid JWT from our Cognito authorizer.
  authorization_type = "JWT"
  authorizer_id    = aws_apigatewayv2_authorizer.cognito_authorizer.id
  # --- END SECURITY ---
}

# 9. Give API Gateway permission to invoke our *admin* Lambda function
resource "aws_lambda_permission" "admin_api_gw_permission" {
  statement_id  = "AllowAPIGatewayToInvokeAdmin"
  action        = "lambda:InvokeFunction"
  function_name = var.createCode_lambda_execution_arn # We use the ARN directly here
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/${aws_apigatewayv2_stage.prod_stage.name}/POST/admin/codes"
}