resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = {
    Name = terraform.workspace == "stg" ? "${var.bucket_name}_stg" : "${var.bucket_name}_prod"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.bucket_versioning_status
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.bucket_encryption_sse_algorithm
    }
  }
}

resource "aws_security_group" "this" {
  name        = terraform.workspace == "stg" ? "S3_security_group_stg" : "S3_security_group_prod"
  description = "A security group for the S3 database"
  vpc_id      = var.vpc_id
  // Only the EC2 instances should be able to communicate with S3
  egress {
    description     = "Allow S3 traffic from the web only"
    from_port       = "3306"
    to_port         = "3306"
    protocol        = "tcp"
    security_groups = var.bucket_security_groups
  }

  tags = {
    Name = terraform.workspace == "stg" ? "S3_security_group_stg" : "S3_security_group_prod"
  }
}

resource "aws_vpc_endpoint" "this" {
  vpc_id       = var.bucket_security_group_vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_vpc_endpoint_route_table_association" "this" {
  route_table_id  = var.endpoint_route_table
  vpc_endpoint_id = aws_vpc_endpoint.this.id
}
