terraform {
  backend "s3" {
    bucket         = "cdnu-terraform-state-571600862515"
    key            = "g5-services-manages/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "cdnu-terraform-locks"
  }
}
