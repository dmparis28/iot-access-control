variable "project_name" {
  description = "A unique name for the project to prefix resources."
  type        = string
}

variable "lambda_function_name" {
  description = "The name of the *hardware* Lambda function."
  type        = string
}

variable "lambda_execution_arn" {
  description = "The execution ARN of the *hardware* Lambda function."
  type        = string
}

# --- ADDED FOR ADMIN API ---
variable "aws_region" {
  description = "The AWS region we are deploying to."
  type        = string
}

variable "admin_auth_user_pool_id" {
  description = "The ID of the Cognito User Pool for admins."
  type        = string
}

variable "admin_auth_user_pool_client_id" {
  description = "The App Client ID of the Cognito User Pool."
  type        = string
}

variable "createCode_lambda_execution_arn" {
  description = "The execution ARN of the AdminCreateCode Lambda function."
  type        = string
}
# --- END ADDED ---