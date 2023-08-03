module "base_project_ECR" {
  source   = "../common/ecr"
  ecr_name = terraform.workspace == "stg" ? "geacco_app_stg" : "geacco_app_prod"
}

resource "aws_security_group" "ECR_security_group" {
  name        = terraform.workspace == "stg" ? "ECR_security_group_stg" : "ECR_security_group_prod"
  description = "A security group for the ECR database"
  vpc_id      = aws_vpc.base_project_VPC.id

  // Only the EC2 instances should be able to communicate with ECR
  egress {
    description     = "Allow ECR traffic from the web only"
    from_port       = "3306"
    to_port         = "3306"
    protocol        = "tcp"
    security_groups = [aws_security_group.EC2_security_group.id]
  }

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_ecr_security_group_stg" : "geacco_app_ecr_security_group_prod"
  }
}

resource "aws_route_table" "base_project_repository_route_table" {
  vpc_id = aws_vpc.base_project_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.base_project_gw.id
  }

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_repository_route_table_stg" : "geacco_app_repository_route_table_prod"
  }
}

resource "aws_route_table_association" "base_project_repository_route_table_association" {
  count          = var.subnet_count.repository_private
  subnet_id      = aws_subnet.base_project_cloud_subnet[count.index].id
  route_table_id = aws_route_table.base_project_repository_route_table.id
}

resource "aws_vpc_endpoint" "ecr_endpoint" {
  vpc_id       = aws_vpc.base_project_VPC.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_vpc_endpoint_route_table_association" "base_project_repository_route_table_association" {
  route_table_id  = aws_route_table.base_project_repository_route_table.id
  vpc_endpoint_id = aws_vpc_endpoint.ecr_endpoint.id
}
