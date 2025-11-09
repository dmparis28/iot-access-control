# This file defines the IAM role (permissions) and the Lambda function (logic).

# 1. Create the IAM Role for our Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-AuthorizeAccess-Role"

  # This 'assume_role_policy' allows the Lambda service to "wear" this role.
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Project = var.project_name
  }
}

# 2. Define the 'Least Privilege' policy for the role
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project_name}-AuthorizeAccess-Policy"
  description = "Policy for the AuthorizeAccess Lambda function"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        # Allows the Lambda to write logs to CloudWatch
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        # Allows the Lambda to READ from our specific DynamoDB table
        # Note: We are not allowing PutItem, DeleteItem, etc. (Least Privilege)
        Action = [
          "dynamodb:GetItem"
        ]
        Effect   = "Allow"
        Resource = var.dynamodb_table_arn # Passed in as a variable
      }
    ]
  })
}

# 3. Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# 4. Zip up our Lambda code from the 'src' directory
data "archive_file" "lambda_zip" {
  type        = "zip"
  # This path is relative to this file:
  # ../ (gets out of lambda_function)
  # ../ (gets out of modules)
  # ../ (gets out of infra)
  # src/AuthorizeAccess (goes into the src folder)
  source_dir  = "../../../src/AuthorizeAccess" # CORRECTED PATH
  output_path = "AuthorizeAccess.zip"
}

# 5. Create the Lambda Function
resource "aws_lambda_function" "authorize_access" {
  function_name = "${var.project_name}-AuthorizeAccess"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler" # The file 'index.js' and the exported function 'handler'
  runtime       = "nodejs18.x"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Pass the DynamoDB table name to the Lambda as an environment variable
  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name # Passed in as aV variable
    }
  }

  tags = {
    Project = var.project_name
  }

  # Ensure the role is created before the function
  depends_on = [aws_iam_role_policy_attachment.lambda_policy_attach]
}