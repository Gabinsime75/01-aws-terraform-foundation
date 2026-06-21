## KMS Key-------------------
# Customer-managed KMS key used to encrypt Terraform state stored in the S3 backend. Key rotation is enabled to meet
# security and compliance best practices.
resource "aws_kms_key" "terraform_state" {
  description             = "Terraform State Encryption Key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "terraform-state-key"
  }
}

## KMS Alias-----------------------
# Friendly alias that provides a stable reference to the Terraform state encryption key. Applications and services
# can reference the alias instead of the KMS Key ID, making future key rotation or replacement easier.
resource "aws_kms_alias" "terraform_state" {
  name          = "alias/terraform-state"
  target_key_id = aws_kms_key.terraform_state.key_id
}

## S3 Bucket-----------------------
# S3 bucket used as the centralized remote backend for Terraform state files. The bucket itself is created
# separately from its security controls (encryption, versioning, public access block, lifecycle policies)
# to follow Terraform and AWS best practices.
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name
  tags = {
    Name = var.bucket_name
  }
}

## Object Versioning--------------------
# Enables object versioning for the Terraform state bucket.Every change to a state file creates a new version, allowing
# recovery from accidental deletions, corruption, or unwanted modifications. Versioning is a critical best practice for
# production Terraform backends.
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

## Bucket Encryption--------------------
# Enforces default server-side encryption for all objects stored in the Terraform state bucket. AWS KMS is used
# instead of the default S3-managed encryption to provide stronger security controls, auditability, and key management.
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

## Block Public Access--------------------
# Prevents any form of public access to the Terraform state bucket, even if a bucket policy or object ACL is accidentally
# configured to allow public access. This provides an additional security layer beyond IAM permissions and bucket policies.
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

## Lifecycle Policy--------------------
# Automatically manages old versions of Terraform state files created by S3 versioning. Previous object versions are retained 
# for 90 days and then permanently removed to control storage costs while still providing a reasonable recovery window.
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    id     = "ExpireOldVersions"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

## DynamoDB Lock Table--------------------
# DynamoDB table used by Terraform for state locking. Prevents multiple users or CI/CD pipelines from modifying
# the same Terraform state file simultaneously, which could result in state corruption or inconsistent infrastructure.
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = var.dynamodb_table_name
  }
}



