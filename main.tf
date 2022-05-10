provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  cloud {
    organization = "atlantic-labs"

    workspaces {
      name = "backend-services"
    }
  }
}

module "nfid" {
  source        = "./nfid"
  client_id     = var.CLIENT_ID
  client_secret = var.CLIENT_SECRET
  redirect_uri  = var.REDIRECT_URI
  mint_private_key = var.MINT_PRIVATE_KEY
  infura_url = var.INFURA_URL
  nfid_contract_address = var.NFID_CONTRACT_ADDRESS
  jwt_secret    = var.JWT_SECRET
}
