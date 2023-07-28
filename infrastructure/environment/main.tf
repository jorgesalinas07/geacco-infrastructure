module "base_project_ECR" {
  source   = "../common/ecr"
  ecr_name = terraform.workspace == "stg" ? "geacco_app_stg" : "geacco_app_prod"
}

resource "aws_vpc" "base_project_VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_vpc_stg" : "geacco_app_vpc_prod"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_s3_bucket" "geacco_app_bucket" {
  bucket = "geacco-app-bucket-79eb25"

  tags = {
    Name        = terraform.workspace == "stg" ? "geacco_app_bucket_stg" : "geacco_app_bucket_prod"
  }
}

resource "aws_s3_bucket_versioning" "geacco_app_bucket_versioning" {
  bucket = aws_s3_bucket.geacco_app_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "geacco_app_encryption_configuration" {
  bucket = aws_s3_bucket.geacco_app_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# resource "aws_vpc_endpoint" "s3" {
#   vpc_id       = aws_vpc.main.id
#   service_name = "com.amazonaws.us-west-2.s3"
# }

# resource "aws_vpc_endpoint_route_table_association" "example" {
#   route_table_id  = aws_route_table.example.id
#   vpc_endpoint_id = aws_vpc_endpoint.example.id
# }
