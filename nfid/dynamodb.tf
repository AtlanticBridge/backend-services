resource "aws_dynamodb_table" "nfid_users" {
  name         = "nfid_users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
}
