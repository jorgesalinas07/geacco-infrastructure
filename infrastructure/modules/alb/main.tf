resource "aws_security_group" "this" {
  name        = terraform.workspace == "stg" ? "${var.security_group_name}_stg" : "${var.security_group_name}_prod"
  description = "A security group for the ALB database"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from computer"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = "8000"
    to_port     = "8000"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = terraform.workspace == "stg" ? "${var.security_group_name}_stg" : "${var.security_group_name}_prod"
  }
}

resource "aws_lb_target_group" "this" {
  name                 = var.lb_target_group_name
  port                 = var.lb_target_group_port
  target_type          = var.lb_target_group_target_type
  protocol             = var.lb_target_group_target_protocol
  vpc_id               = var.vpc_id
  deregistration_delay = var.deregistration_delay

  lifecycle { create_before_destroy = true }

  health_check {
    port              = var.lb_target_group_port
    path              = var.lb_target_group_health_check_path
    healthy_threshold = var.lb_target_group_health_check_healthy_threshold
    interval          = var.lb_target_group_health_check_interval
    timeout           = var.lb_target_group_health_check_timeout
  }

}

resource "aws_lb" "this" { // NLB for database is missing
  name               = var.lb_name
  internal           = var.lb_internal
  load_balancer_type = var.lb_target_group_target_type
  security_groups    = var.lb_security_groups
  subnets            = var.lb_subnets
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.lb_listener_port
  protocol          = var.lb_listener_protocol

  default_action {
    target_group_arn = aws_lb_target_group.this.id
    type             = "forward"
  }
}
