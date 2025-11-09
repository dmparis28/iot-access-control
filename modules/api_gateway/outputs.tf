output "api_endpoint_url" {
  description = "The URL for the deployed API Gateway (prod stage)."
  value       = aws_apigatewayv2_stage.prod_stage.invoke_url
}

output "api_key_value" {
  description = "The secret value of the API key for the hardware."
  value       = aws_api_key.hardware_key.value
  sensitive   = true
}