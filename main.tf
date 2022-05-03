provider "aws" {
  region     = "us-east-1"
  access_key = var.ACCESS_KEY
  secret_key = var.SECRET_KEY
}

module "nfid" {
  source        = "./nfid"
  client_id     = var.CLIENT_ID
  client_secret = var.CLIENT_SECRET
  redirect_uri  = var.REDIRECT_URI
  mint_private_key = var.MINT_PRIVATE_KEY
  infura_url = var.INFURA_URL
  nfid_contract_address = var.NFID_CONTRACT_ADDRESS
}
