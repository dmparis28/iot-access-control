output "table_name" {
  description = "The name of the DynamoDB logs table."
  value       = aws_dynamodb_table.logs_table.name
}

output "table_arn" {
  description = "The ARN of the DynamoDB logs table."
  value       = aws_dynamodb_table.logs_table.arn
}