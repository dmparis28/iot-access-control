variable "project_name" {
  description = "A unique name for the project to prefix resources."
  type        = string
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table."
  type        = string
}