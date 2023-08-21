resource "aws_subnet" "this" {
  count             = var.subnet_count.db_private
  vpc_id            = var.vpc_id
  cidr_block        = var.db_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_db_subnet_stg_${count.index}" : "geacco_app_db_subnet_prod_${count.index}"
  }
}

resource "aws_route_table" "this" {
  vpc_id = var.vpc_id

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_db_route_table_stg" : "geacco_app_db_route_table_prod"
  }
}

resource "aws_route_table_association" "this" {
  count          = var.subnet_count.db_private
  subnet_id      = aws_subnet.this[count.index].id
  route_table_id = aws_route_table.this.id
}

resource "aws_security_group" "this" {
  name        = terraform.workspace == "stg" ? "RDS_security_group_stg" : "RDS_security_group_prod"
  description = "A security group for the RDS database"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow RDS traffic from the web only (EC2)"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.ingress_security_group
  }

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

resource "aws_db_subnet_group" "this" {
  name       = terraform.workspace == "stg" ? "${var.db_name}_subnet_group_stg" : "${var.db_name}_subnet_group_prod"
  subnet_ids = [for subnet in aws_subnet.this : subnet.id]

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_db_subnet_group_stg" : "geacco_app_db_subnet_group_prod"
  }
}

resource "aws_db_instance" "geacco_db_instance" {
  identifier             = terraform.workspace == "stg" ? "geaccodbstg" : "geaccodbprod"
  allocated_storage      = var.settings.database.allocated_storage
  db_name                = terraform.workspace == "stg" ? "${var.db_name}_stg" : "${var.db_name}_prod"
  engine                 = var.settings.database.engine
  engine_version         = var.settings.database.engine_version
  instance_class         = var.settings.database.instance_class
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.id
  vpc_security_group_ids = [aws_security_group.this.id]
  skip_final_snapshot    = var.settings.database.skip_final_snapshot
}
