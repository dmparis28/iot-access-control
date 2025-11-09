# This file defines our main database - the AccessControl table.

resource "aws_dynamodb_table" "access_table" {
  # The table name is prefixed with our project name for uniqueness.
  name         = "${var.project_name}-AccessCodes"
  billing_mode = "PAY_PER_REQUEST" # This is key for our low-cost model.
  hash_key     = "accessCode"      # This is the primary key we'll query against.

  attribute {
    name = "accessCode"
    type = "S" # S means 'String'
  }

  tags = {
    Project = var.project_name
  }
}