# This file defines what values to output after Terraform runs.
# These are the critical values we'll need for Phase 2.
# They now reference the outputs from our modules.

output "api_endpoint_url" {
  description = "The URL for the deployed API Gateway (prod stage)."
  value       = module.http_api.api_endpoint_url
}

output "api_key_value" {
  description = "The secret value of the API key for the hardware."
  value       = module.http_api.api_key_value
  sensitive   = true # This hides it from the console output
}