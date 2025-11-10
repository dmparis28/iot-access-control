# This file defines our Admin User Pool using Amazon Cognito.
# This will handle all user sign-up, sign-in, and password resets.

resource "aws_cognito_user_pool" "admin_pool" {
  name = "${var.project_name}-AdminPool"

  # We will let users sign in with their email address as their username
  username_attributes = ["email"]

  # Standard password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # Allow Cognito to handle sending "forgot password" emails, etc.
  auto_verified_attributes = ["email"]

  tags = {
    Project = var.project_name
  }
}

# This is the "App" that our future website will use to talk to Cognito
resource "aws_cognito_user_pool_client" "admin_client" {
  name         = "${var.project_name}-AdminClient"
  user_pool_id = aws_cognito_user_pool.admin_pool.id

  # This setting is required for web apps to work
  generate_secret = false

  # --- THIS IS THE FIX ---
  # We must use the "ALLOW_" prefix for all auth flows
  # if we use any of them.
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
  # --- END FIX ---
}