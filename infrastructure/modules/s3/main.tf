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
  count = var.create_security_group ? 1 : 0
  name        = terraform.workspace == "stg" ? "${var.bucket_security_group_name}_stg" : "${var.bucket_security_group_name}_prod"
  description = "A security group for the S3 database"
  vpc_id      = var.bucket_security_vpc_id
  // Only the EC2 instances should be able to communicate with S3
  egress {
    description     = "Allow S3 traffic from the web only"
    from_port       = "3306"
    to_port         = "3306"
    protocol        = "tcp"
    security_groups = var.bucket_security_groups
  }

  tags = {
    Name = terraform.workspace == "stg" ? "${var.bucket_security_group_name}_stg" : "${var.bucket_security_group_name}_prod"
  }
}

resource "aws_vpc_endpoint" "this" {
  count = var.create_security_group ? 1 : 0
  vpc_id       = var.bucket_security_group_vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_vpc_endpoint_route_table_association" "base_project_bucket_endpoint_route_table_association" {
  count = var.create_endpoint_route_table ? 1 : 0
  route_table_id  = var.endpoint_route_table
  vpc_endpoint_id = aws_vpc_endpoint[0].this.id
}
