output "user_pool_id" {
  description = "The ID of the Cognito User Pool."
  value       = aws_cognito_user_pool.admin_pool.id
}

output "user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client (for our web app)."
  value       = aws_cognito_user_pool_client.admin_client.id
}