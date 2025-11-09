# This file provisions sample data to our DynamoDB table for testing.
# We will create two test codes: one valid, one expired.

# 1. A standard, always-valid code
resource "aws_dynamodb_table_item" "test_code_valid" {
  table_name = module.access_table.table_name
  hash_key   = "accessCode" # This is the primary key "accessCode"

  # The 'item' is a JSON representation of the DynamoDB object
  item = jsonencode({
    "accessCode" = { "S" = "1234" },
    "userName"   = { "S" = "Test User (Valid)" },
    "role"       = { "S" = "Resident" }
  })
}

# 2. A temporary, EXPIRED code
resource "aws_dynamodb_table_item" "test_code_expired" {
  table_name = module.access_table.table_name
  hash_key   = "accessCode"

  item = jsonencode({
    "accessCode" = { "S" = "5678" },
    "userName"   = { "S" = "Test User (Expired)" },
    "role"       = { "S" = "Contractor" },
    # We add an 'expirationTimestamp' as a Number (N).
    # This is a Unix timestamp for Jan 1, 2024. It is in the past.
    "expirationTimestamp" = { "N" = "1704067200" }
  })
}