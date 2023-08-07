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

resource "aws_route_table" "base_project_gt_route_table" {
  vpc_id = aws_vpc.base_project_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.base_project_gw.id
  }

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_gt_route_table_stg" : "geacco_app_gt_route_table_prod"
  }
}

resource "aws_route_table_association" "base_project_route_table_association" {
  count          = var.subnet_count.cloud_private
  subnet_id      = aws_subnet.base_project_cloud_subnet[count.index].id
  route_table_id = aws_route_table.base_project_gt_route_table.id
}
