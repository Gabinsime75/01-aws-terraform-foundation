provider "aws" {

  region = var.aws_region

  default_tags {

    tags = {

      Project     = "aws-enterprise-foundation"
      Environment = "management"
      ManagedBy   = "Terraform"
      Repository  = "01-aws-terraform-foundation"

    }

  }

}