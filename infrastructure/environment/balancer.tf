resource "aws_security_group" "ALB_security_group" {
  name        = terraform.workspace == "stg" ? "ALB_security_group_stg" : "ALB_security_group_prod"
  description = "A security group for the ALB database"
  vpc_id      = aws_vpc.base_project_VPC.id

  // Allow all outgoing traffic in ALB
  egress {
    description     = "Allow ALB traffic from the web only"
    from_port       = "0"
    to_port         = "0"
    protocol        = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  ingress {
    description = "Allow SSH from computer"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  # EC2 instances should be accessible anywhere on the internet via HTTP.
  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # EC2 instances should be accessible anywhere on the internet via HTTP.
  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = "8000"
    to_port     = "8000"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # EC2 instances should be accessible anywhere on the internet via HTTP.
  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_alb_security_group_stg" : "geacco_app_alb_security_group_prod"
  }
}

resource "aws_lb_target_group" "base_project_alb_target_group" {
  name        = "geacco-alb-target-group"
  port        = 80
  target_type = "instance"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.base_project_VPC.id
}

resource "aws_alb_target_group_attachment" "base_project_alb_attachment" {
  count         = var.settings.web_app.count
  target_group_arn = aws_lb_target_group.base_project_alb_target_group.arn
  target_id        = aws_instance.base_project_EC2_instance[count.index].id
  port        = 80
}

resource "aws_lb" "base_project_alb" { // NLB for database is missing
  name               = "geacco-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ALB_security_group.id]
  subnets            = [for subnet in aws_subnet.base_project_cloud_subnet : subnet.id]
}

resource "aws_lb_listener" "base_project_alb_listener" {
  load_balancer_arn = aws_lb.base_project_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# resource "aws_lb_listener_rule" "base_project_alb_listener_rule" {
#   listener_arn = aws_lb_listener.base_project_alb_listener.arn
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.base_project_alb_target_group.arn

#   }

#   condition {
#     path_pattern {
#       values = ["/var/www/html/index.html"]
#     }
#   }
# }

data "aws_iam_policy_document" "base_project_ecs_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "base_project_ecs_iam_role" {
  name               = "base-project-ecs-iam-role"
  assume_role_policy = data.aws_iam_policy_document.base_project_ecs_policy.json
}


resource "aws_iam_role_policy_attachment" "base_project_ecs_role_policy_attachment" {
  role       = aws_iam_role.base_project_ecs_iam_role.name
  #policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerServiceforEC2Role"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "base_project_ecs_iam_profile" {
  name = "base-project-ecs-iam-role"
  role = aws_iam_role.base_project_ecs_iam_role.name
}

resource "aws_launch_configuration" "base_project_ecs_launch_config" {
    image_id      = data.aws_ami.ubuntu.id
    # image_id             = "ami-094d4d00fd7462815" //Change to variable to ubuntu
    iam_instance_profile = aws_iam_instance_profile.base_project_ecs_iam_profile.name
    security_groups      = [aws_security_group.EC2_security_group.id]
    user_data            = "#!/bin/bash\necho ECS_CLUSTER=base-project-ecs-cluster >> /etc/ecs/ecs.config"
    instance_type        = var.settings.web_app.instance_type
}

resource "aws_autoscaling_group" "base_project_autoscaling_group" {
    name                      = "base_project_autoscaling_group"
    # vpc_zone_identifier       = [aws_subnet.pub_subnet.id]
    vpc_zone_identifier = [for subnet in aws_subnet.base_project_cloud_subnet : subnet.id]
    launch_configuration      = aws_launch_configuration.base_project_ecs_launch_config.name

    desired_capacity          = 2
    min_size                  = 1
    max_size                  = 10
    health_check_grace_period = 300
    health_check_type         = "EC2"
}

resource "aws_ecs_cluster" "base_project_ecs_cluster" {
    name  = "base-project-ecs-cluster"
}

resource "aws_ecs_task_definition" "base_project_ecs_task_definition" {
  family                = "base_project_image"
  container_definitions = jsonencode([
    {
      essential = true
      memory    = 512
      name      = "base_project_image"
      cpu       = 2
      image     = "${var.REPOSITORY_URL}:${var.IMAGE_TAG}"
      environment = []
      portMappings = [
        {
          containerPort = 8000,
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "base_project_ecs_service" {
  name            = "base_project_ecs_service"
  cluster         = aws_ecs_cluster.base_project_ecs_cluster.id
  task_definition = aws_ecs_task_definition.base_project_ecs_task_definition.arn
  desired_count   = 2

  load_balancer {
    target_group_arn = aws_lb_target_group.base_project_alb_target_group.arn
    container_name   = "base_project_image"
    container_port   = 8000
  }
}
