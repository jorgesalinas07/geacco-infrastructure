resource "aws_s3_bucket" "geacco_app_bucket" {
  bucket = "geacco-app-bucket"

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_bucket_stg" : "geacco_app_bucket_prod"
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

resource "aws_security_group" "S3_security_group" {
  name        = terraform.workspace == "stg" ? "S3_security_group_stg" : "S3_security_group_prod"
  description = "A security group for the S3 database"
  vpc_id      = aws_vpc.base_project_VPC.id

  // Only the EC2 instances should be able to communicate with S3
  egress {
    description     = "Allow S3 traffic from the web only"
    from_port       = "3306"
    to_port         = "3306"
    protocol        = "tcp"
    security_groups = [aws_security_group.EC2_security_group.id]
  }

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_s3_security_group_stg" : "geacco_app_s3_security_group_prod"
  }
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id       = aws_vpc.base_project_VPC.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_vpc_endpoint_route_table_association" "base_project_bucket_endpoint_route_table_association" {
  route_table_id  = aws_route_table.base_project_gt_route_table.id
  vpc_endpoint_id = aws_vpc_endpoint.s3_endpoint.id
}
