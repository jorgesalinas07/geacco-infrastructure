# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 4.9.0"
#     }
#   }

#   backend "s3" {
#     bucket  = "geacco-app-tfstate-79eb25"
#     key     = "global/s3/state.tfstate"
#     region  = "us-east-1"
#     encrypt = true
#   }
# }

# provider "aws" {
#   region = "us-east-1"
# }

provider "aws" {
  #region     = "us-west-2"
}

resource "aws_s3_bucket" "project_terraform_state" {
  bucket = "geacco-app-tfstate-79eb25"
}

resource "aws_s3_bucket_versioning" "project_terraform_state_versioning" {
  bucket = aws_s3_bucket.project_terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "project_terraform_state_encryption_configuration" {
  bucket = aws_s3_bucket.project_terraform_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
