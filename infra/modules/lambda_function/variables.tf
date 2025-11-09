variable "project_name" {
  description = "A unique name for the project to prefix resources."
  type        = string
}

variable "dynamodb_table_name" {
  description = "The name of the main DynamoDB access table."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "The ARN of the main DynamoDB access table."
  type        = string
}

# --- ADDED FOR LOGGING ---
variable "dynamodb_logs_table_name" {
  description = "The name of the DynamoDB logs table."
  type        = string
}

variable "dynamodb_logs_table_arn" {
  description = "The ARN of the DynamoDB logs table."
  type        = string
}
# --- END ADDED ---