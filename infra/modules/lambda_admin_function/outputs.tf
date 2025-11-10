output "createCode_lambda_execution_arn" {
  description = "The execution ARN of the CreateCode Lambda function."
  value       = aws_lambda_function.admin_create_code.arn
}