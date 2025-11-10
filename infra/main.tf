# This orchestrates all our modules.

# 1. DynamoDB Table (for Access Codes)
module "access_table" {
  source       = "./modules/dynamodb_table"
  project_name = var.project_name
}

# 2. DynamoDB Table (for Access Logs)
module "access_logs_table" {
  source       = "./modules/dynamodb_logs_table"
  project_name = var.project_name
}

# 3. Lambda Function (for Hardware)
module "authorize_access_lambda" {
  source       = "./modules/lambda_function"
  project_name = var.project_name
  
  dynamodb_table_name      = module.access_table.table_name
  dynamodb_table_arn       = module.access_table.table_arn
  dynamodb_logs_table_name = module.access_logs_table.table_name
  dynamodb_logs_table_arn  = module.access_logs_table.table_arn
}

# --- ADDED FOR ADMIN API ---
# 4. Lambda Function (for Admins)
module "admin_lambda_functions" {
  source       = "./modules/lambda_admin_function"
  project_name = var.project_name

  # Give it access to the main codes table
  dynamodb_table_name = module.access_table.table_name
  dynamodb_table_arn  = module.access_table.table_arn
}

# 5. Cognito User Pool (for Admin Auth)
module "admin_auth" {
  source       = "./modules/cognito_auth"
  project_name = var.project_name
}
# --- END ADDED ---

# 6. API Gateway (for Hardware AND Admins)
# --- THIS BLOCK IS THE FIX ---
module "http_api" {
  source                 = "./modules/api_gateway"
  project_name           = var.project_name
  aws_region             = var.aws_region # Added this required argument
  
  # Hardware Lambda
  lambda_function_name   = module.authorize_access_lambda.lambda_function_name
  lambda_execution_arn   = module.authorize_access_lambda.lambda_execution_arn
  # lambda_invoke_arn was removed, as it's unsupported

  # Admin Lambda
  createCode_lambda_execution_arn = module.admin_lambda_functions.createCode_lambda_execution_arn # Added
  
  # Cognito Auth
  admin_auth_user_pool_id        = module.admin_auth.user_pool_id        # Added
  admin_auth_user_pool_client_id = module.admin_auth.user_pool_client_id # Added
}
# --- END FIX ---