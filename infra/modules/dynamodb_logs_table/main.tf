# This file defines our new AccessLogs table.
# We use a unique "logId" as the key so writes are fast and evenly distributed.

resource "aws_dynamodb_table" "logs_table" {
  name         = "${var.project_name}-AccessLogs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "logId" # This is the primary key (Partition Key)

  attribute {
    name = "logId"
    type = "S" # S means 'String'
  }

  tags = {
    Project = var.project_name
  }
}