resource "aws_dynamodb_table" "dynamodb" {
  name         = "${var.table_name}_dynamodb"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.hash_key
  range_key    = var.range_key
  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }
  attribute {
    name = var.range_key
    type = var.range_key_type
  }
}
