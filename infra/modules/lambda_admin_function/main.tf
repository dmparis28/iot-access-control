# This file defines the IAM role and Lambda for our ADMIN functions.
# Note the IAM policy is different; this one can WRITE to DynamoDB.

# 1. Create the IAM Role for our Admin Lambda
resource "aws_iam_role" "lambda_admin_exec_role" {
  name = "${var.project_name}-AdminLambda-Role"

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
resource "aws_iam_policy" "lambda_admin_policy" {
  name        = "${var.project_name}-AdminLambda-Policy"
  description = "Policy for the Admin Lambda functions"

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
        # Allows this admin function to CREATE, UPDATE, and DELETE codes.
        # This is more permissive than our read-only hardware lambda.
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Effect   = "Allow"
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

# 3. Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_admin_exec_role.name
  policy_arn = aws_iam_policy.lambda_admin_policy.arn
}

# 4. Zip up our NEW AdminCreateCode function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../src/AdminCreateCode" # Path is relative to the infra/ directory
  output_path = "AdminCreateCode.zip"
}

# 5. Create the AdminCreateCode Lambda Function
resource "aws_lambda_function" "admin_create_code" {
  function_name = "${var.project_name}-AdminCreateCode"
  role          = aws_iam_role.lambda_admin_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }

  tags = {
    Project = var.project_name
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_policy_attach]
}