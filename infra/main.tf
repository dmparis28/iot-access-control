# This orchestrates all our modules.

# 1. DynamoDB Table (for Access Codes)
module "access_table" {
  source       = "./modules/dynamodb_table"
  project_name = var.project_name
}

# --- ADDED FOR LOGGING ---
# 2. DynamoDB Table (for Access Logs)
module "access_logs_table" {
  source       = "./modules/dynamodb_logs_table"
  project_name = var.project_name
}
# --- END ADDED ---

# 3. Lambda Function
module "authorize_access_lambda" {
  source       = "./modules/lambda_function"
  project_name = var.project_name
  
  # Original table
  dynamodb_table_name = module.access_table.table_name
  dynamodb_table_arn  = module.access_table.table_arn

  # --- ADDED FOR LOGGING ---
  # New logs table
  dynamodb_logs_table_name = module.access_logs_table.table_name
  dynamodb_logs_table_arn  = module.access_logs_table.table_arn
  # --- END ADDED ---
}

# 4. API Gateway
module "http_api" {
  source                  = "./modules/api_gateway"
  project_name            = var.project_name
  lambda_invoke_arn       = module.authorize_access_lambda.lambda_invoke_arn
  lambda_function_name    = module.authorize_access_lambda.lambda_function_name
  lambda_execution_arn    = module.authorize_access_lambda.lambda_execution_arn
}