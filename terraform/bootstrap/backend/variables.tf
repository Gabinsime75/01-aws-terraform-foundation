variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "bucket_name" {
  description = "Terraform state bucket"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Terraform lock table"
  type        = string
}

