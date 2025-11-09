output "lambda_invoke_arn" {
  description = "The ARN to use for invoking the Lambda function."
  value       = aws_lambda_function.authorize_access.invoke_arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.authorize_access.function_name
}

output "lambda_execution_arn" {
  description = "The execution ARN of the Lambda function."
  value       = aws_lambda_function.authorize_access.arn
}