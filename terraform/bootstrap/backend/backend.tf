terraform {
  backend "s3" {
    bucket         = "cloudhustler-tfstate-prod"
    key            = "bootstrap/backend/terraform.tfstate"
    region         = "us-east-2"
    use_lockfile   = true
    encrypt        = true
  }
}