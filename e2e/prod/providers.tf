provider "aws" {
  region = "us-west-2"
  profile = "prod.kaixo.io"
}

terraform {
  backend "s3" {
    bucket  = "kaixo-prod-tofu"
    key     = "stage/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}