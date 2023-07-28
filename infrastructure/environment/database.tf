resource "aws_subnet" "base_project_db_subnet" {
  count             = var.subnet_count.db_private
  vpc_id            = aws_vpc.base_project_VPC.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = data.aws_availability_zones.available.state[count.index]

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_db_subnet_stg_${count.index}" : "geacco_app_db_subnet_prod_${count.index}"
  }
}

resource "aws_route_table" "base_project_db_route_table" {
  vpc_id = aws_vpc.base_project_VPC.id

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_db_table_stg" : "geacco_app_db_table_prod"
  }
}

resource "aws_route_table_association" "base_project_db_route_table_association" {
  count          = var.subnet_count.db_private
  subnet_id      = aws_subnet.base_project_db_subnet[count.index].id
  route_table_id = aws_route_table.base_project_db_route_table.id
}

resource "aws_security_group" "RDS_security_group" {
  name        = terraform.workspace == "stg" ? "RDS_security_group_stg" : "RDS_security_group_prod"
  description = "A security group for the RDS database"
  vpc_id      = aws_vpc.base_project_VPC.id

  // Only the EC2 instances should be able to communicate with RDS
  egress {
    description     = "Allow RDS traffic from the web only"
    from_port       = "3306"
    to_port         = "3306"
    protocol        = "tcp"
    security_groups = [aws_security_group.EC2_security_group.id]
  }

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_rds_security_group_stg" : "geacco_app_rds_security_group_prod"
  }
}

resource "aws_db_subnet_group" "geacco_db_subnet_group" {
  name       = terraform.workspace == "stg" ? "geacco_app_db_subnet_group_stg" : "geacco_app_db_subnet_group_prod"
  subnet_ids = [for subnet in aws_subnet.base_project_db_subnet : subnet.id]

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_db_subnet_group_stg" : "geacco_app_db_subnet_group_prod"
  }
}

resource "aws_db_instance" "geacco_db_instance" {
  allocated_storage      = var.settings.allocated_storage
  db_name                = terraform.workspace == "stg" ? "geacco_db_stg" : "geacco_db_prod"
  engine                 = var.settings.engine
  engine_version         = var.settings.engine_version
  instance_class         = var.settings.instance_class
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.geacco_db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.RDS_security_group.id]
  skip_final_snapshot    = var.settings.skip_final_snapshot
}
