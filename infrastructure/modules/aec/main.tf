data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_security_group" "this" {
  name   = terraform.workspace == "stg" ? "${var.ec_name}_security_group_stg" : "${var.ec_name}_security_group_prod"
  vpc_id = var.vpc_id

  ingress {
    description     = "Allow EC traffic from the web only (EC2)"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.ec_security_groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_replication_group" "base_project_EC_replication_group" {
  replication_group_id    = var.replication_group_id
  description             = "Redis from Geacco app"
  node_type               = var.node_type
  port                    = var.port
  engine_version          = var.engine_version
  subnet_group_name       = aws_elasticache_subnet_group.this.name
  security_group_ids      = [aws_security_group.this.id]
  num_node_groups         = 1
  replicas_per_node_group = 1

}

resource "aws_subnet" "this" {
  count             = var.subnet_count.EC_private
  vpc_id            = var.vpc_id
  cidr_block        = var.EC_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = terraform.workspace == "stg" ? "${var.ec_name}_subnet_stg_${count.index}" : "${var.ec_name}_subnet_prod_${count.index}"
  }
}

resource "aws_route_table" "this" {
  vpc_id = var.vpc_id

  tags = {
    Name = terraform.workspace == "stg" ? "${var.ec_name}_route_table_stg" : "${var.ec_name}_route_table_prod"
  }
}

resource "aws_route_table_association" "this" {
  count          = var.subnet_count.EC_private
  subnet_id      = aws_subnet.this[count.index].id
  route_table_id = aws_route_table.this.id
}

resource "aws_elasticache_subnet_group" "this" {
  name       = terraform.workspace == "stg" ? "${var.ec_name}-stg" : "${var.ec_name}-prod"
  subnet_ids = [for subnet in aws_subnet.this : subnet.id]
}
