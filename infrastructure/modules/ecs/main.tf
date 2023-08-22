resource "aws_ecs_cluster" "base_project_ecs_cluster" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_task_definition" "base_project_ecs_task_definition" {
  family                   = var.task_definition_family
  network_mode             = var.task_definition_network_mode
  execution_role_arn       = aws_iam_role.base_project_ecs_execution_iam_role.arn
  requires_compatibilities = var.requires_compatibilities
  container_definitions = jsonencode([
    {
      essential   = true
      memory      = 256
      name        = "base_project_image"
      cpu         = 256
      image       = "${var.REPOSITORY_URL}:${var.IMAGE_TAG}"
      environment = [
      {
        name  = "DEBUG",
        value = "on"
      },
      {
        name  = "DATABASE_URL",
        value = "postgres://geaccousername:password@${aws_db_instance.geacco_db_instance.address}:${aws_db_instance.geacco_db_instance.port}/${aws_db_instance.geacco_db_instance.db_name}" //Change to secret manager
      },
      {
        name  = "SECRET_KEY",
        value = "0h7@rhy%nzmm*6rjz--%631e4tqji@m9q-tk@c!2fdir%vu9y-" //Change to secret manager
      },
      {
        name  = "REDIS_URL",
        value = "redis://${aws_elasticache_replication_group.base_project_EC_replication_group.primary_endpoint_address}:6379/0"
      },
      {
        name  = "POSTGRES_PASSWORD",
        value = "password" //Change to secrets manager
      },
      {
        name  = "ENV",
        value = "build"
      }
    ],
      portMappings = [
        {
          containerPort = 8001,
          hostPort      = 8001,
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
          logDriver = "awslogs",
          options = {
            awslogs-group = "base_project_image_logs",
            awslogs-create-group = "true", //Not taken as bool
            awslogs-region = "us-east-1",
            awslogs-stream-prefix = "ecs",
          }
      },
    }
  ])
}




resource "aws_iam_role" "base_project_ecs_execution_iam_role" {
  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_execution_role.json
}


resource "aws_iam_role_policy_attachment" "base_project_ecs_task_role_policy_attachment" {
  count = length(var.iam_policy_arn_task_ecs)
  role  = aws_iam_role.base_project_ecs_execution_iam_role.name
  policy_arn = var.iam_policy_arn_task_ecs[count.index]
}

data "aws_iam_policy_document" "ecs_tasks_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_ecs_service" "base_project_ecs_service" {
  depends_on           = [aws_lb_listener.base_project_alb_listener]
  name                 = var.ecs_service_name

  launch_type          = var.ecs_service_launch_type
  cluster              = aws_ecs_cluster.base_project_ecs_cluster.id
  force_new_deployment = var.ecs_force_new_deployment
  task_definition      = aws_ecs_task_definition.base_project_ecs_task_definition.arn
  desired_count = 2
  deployment_maximum_percent = 150
  deployment_minimum_healthy_percent = 50

  load_balancer {
    target_group_arn = aws_lb_target_group.base_project_alb_target_group.arn
    container_name   = var.load_balancer_container_name
    container_port   = 8001
  }

  network_configuration {
    subnets            = [for subnet in aws_subnet.base_project_cloud_subnet : subnet.id]
    security_groups = [aws_security_group.ECS_security_group.id]
  }
}

resource "aws_security_group" "ECS_security_group" {
  name        = terraform.workspace == "stg" ? "ECS_security_group_stg" : "ECS_security_group_prod"
  description = "A security group for the ECS"
  vpc_id      = aws_vpc.base_project_VPC.id


  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = "8001"
    to_port     = "8001"
    protocol    = "tcp"
    security_groups = [
      "${aws_security_group.ALB_security_group.id}",
    ]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_ecs_security_group_stg" : "geacco_app_ecs_security_group_prod"
  }
}
