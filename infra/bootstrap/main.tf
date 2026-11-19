terraform {
  required_version = ">=1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

#looks up your account id, so the bucket name is unique
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "tfstate" {
  bucket = "doc-intake-tfstate-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true #terraform refuses to delete bucket by accident
  }
}

#versioning keeps old copies of the state file, so you can roll back to a previous version if needed
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#State can contain sensitive values, so this bucket must never be public
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket_name" {
  value = aws_s3_bucket.tfstate.bucket
}