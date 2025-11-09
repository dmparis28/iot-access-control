# This is the new root main.tf. It's clean and just calls our modules.
# This "orchestrates" the other modules.

# 1. DynamoDB Table
module "access_table" {
  source       = "./modules/dynamodb_table"
  project_name = var.project_name
}

# 2. Lambda Function
module "authorize_access_lambda" {
  source       = "./modules/lambda_function"
  project_name = var.project_name
  # We pass the table name from our first module into our second.
  dynamodb_table_name = module.access_table.table_name
  dynamodb_table_arn  = module.access_table.table_arn
}

# 3. API Gateway
module "http_api" {
  source                  = "./modules/api_gateway"
  project_name            = var.project_name
  lambda_invoke_arn       = module.authorize_access_lambda.lambda_invoke_arn
  lambda_function_name    = module.authorize_access_lambda.lambda_function_name
  lambda_execution_arn    = module.authorize_access_lambda.lambda_execution_arn
}