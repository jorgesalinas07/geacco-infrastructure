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
