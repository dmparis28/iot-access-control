# This file defines what values to output after Terraform runs.
# These are the critical values we'll need for Phase 2.
# They now reference the outputs from our modules.

output "api_endpoint_url" {
  description = "The URL for the deployed API Gateway (prod stage)."
  value       = module.http_api.api_endpoint_url
}