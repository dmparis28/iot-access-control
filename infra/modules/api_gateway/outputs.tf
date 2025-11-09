output "api_endpoint_url" {
  description = "The URL for the deployed API Gateway (prod stage)."
  value       = aws_apigatewayv2_stage.prod_stage.invoke_url
}

# The "api_key_value" output has been deleted.