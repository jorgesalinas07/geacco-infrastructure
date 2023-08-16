resource "aws_subnet" "base_project_db_subnet" {
  count             = var.subnet_count.db_private
  vpc_id            = aws_vpc.base_project_VPC.id
  cidr_block        = var.db_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_db_subnet_stg_${count.index}" : "geacco_app_db_subnet_prod_${count.index}"
  }
}

resource "aws_route_table" "base_project_db_route_table" {
  vpc_id = aws_vpc.base_project_VPC.id

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_db_route_table_stg" : "geacco_app_db_route_table_prod"
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

  // RDS should be on a private subnet and naccessible via the internet.

  // Only the EC2 instances should be able to communicate with RDS // Checked
  ingress {
    description     = "Allow RDS traffic from the web only (EC2)"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.EC2_security_group.id, aws_security_group.ECS_security_group.id]
  }

  // Allow all outgoing traffic in ALB
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
  identifier             = terraform.workspace == "stg" ? "geaccodbstg" : "geaccodbprod"
  allocated_storage      = var.settings.database.allocated_storage
  db_name                = terraform.workspace == "stg" ? "geacco_db_stg" : "geacco_db_prod"
  engine                 = var.settings.database.engine
  engine_version         = var.settings.database.engine_version
  instance_class         = var.settings.database.instance_class
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.geacco_db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.RDS_security_group.id]
  skip_final_snapshot    = var.settings.database.skip_final_snapshot
}
