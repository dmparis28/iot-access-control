# This file defines the IAM role (permissions) and the Lambda function (logic).

# 1. Create the IAM Role for our Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-AuthorizeAccess-Role"

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
        # Allows READ from our main AccessCodes table
        Action = [
          "dynamodb:GetItem"
        ]
        Effect   = "Allow"
        Resource = var.dynamodb_table_arn # Original table
      },
      {
        # Allows WRITE to our new AccessLogs table
        Action = [
          "dynamodb:PutItem"
        ]
        Effect   = "Allow"
        Resource = var.dynamodb_logs_table_arn # New logs table
      }
    ]
  })
}

# 3. Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# 4. Zip up our Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../src/AuthorizeAccess" # Path is relative to the infra/ directory
  output_path = "AuthorizeAccess.zip"
}

# 5. Create the Lambda Function
resource "aws_lambda_function" "authorize_access" {
  function_name = "${var.project_name}-AuthorizeAccess"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME      = var.dynamodb_table_name      # Original table
      LOGS_TABLE_NAME = var.dynamodb_logs_table_name # New logs table
      
      # This forces an update on every 'apply' to deploy new code
      LAST_UPDATED_ON = timestamp()
    }
  }

  tags = {
    Project = var.project_name
  }
  
  depends_on = [aws_iam_role_policy_attachment.lambda_policy_attach]
}