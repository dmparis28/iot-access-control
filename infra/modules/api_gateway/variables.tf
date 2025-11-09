variable "project_name" {
  description = "A unique name for the project to prefix resources."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "The ARN for invoking the Lambda function."
  type        = string
}

variable "lambda_function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "lambda_execution_arn" {
  description = "The execution ARN of the Lambda function."
  type        = string
}