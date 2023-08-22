resource "aws_security_group" "ALB_security_group" {
  name        = terraform.workspace == "stg" ? "ALB_security_group_stg" : "ALB_security_group_prod"
  description = "A security group for the ALB database"
  vpc_id      = aws_vpc.base_project_VPC.id

  // Allow all outgoing traffic in ALB
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   description = "Allow SSH from computer"
  #   from_port   = "22"
  #   to_port     = "22"
  #   protocol    = "tcp"
  #   cidr_blocks = ["${var.my_ip}/32"]
  # }

  # EC2 instances should be accessible anywhere on the internet via HTTP.
  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # EC2 instances should be accessible anywhere on the internet via HTTP.
  # ingress {
  #   description = "Allow all traffic throught HTTP"
  #   from_port   = "8000"
  #   to_port     = "8000"
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

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
  name        = terraform.workspace == "stg" ? "geacco-alb-target-group-stg" : "geacco-alb-target-group-prod"
  port        = 8001
  target_type = "ip"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.base_project_VPC.id
  deregistration_delay = 5// Not so sure

  lifecycle { create_before_destroy=true }

  health_check {
  #   path = "/api/1/resolve/default?path=/service/my-service"
    port = 8001
    #path = "/"
    path = "/health"
    #path = "/admin"
    healthy_threshold = 2 // Not so sure
  #   unhealthy_threshold = 2
  #   timeout = 2
    interval = 5// Not so sure
    timeout = 2// Not so sure
    matcher = "200,301,302"  # has to be HTTP 200 or fails
  }

  # health_check {
  #   healthy_threshold   = "3"
  #   interval            = "15"
  #   path                = "/"
  #   protocol            = "HTTP"
  #   unhealthy_threshold = "10"
  #   timeout             = "10"
  # }
}

# resource "aws_alb_target_group_attachment" "base_project_alb_attachment" {
#   count         = var.settings.web_app.count
#   target_group_arn = aws_lb_target_group.base_project_alb_target_group.arn
#   target_id        = aws_instance.base_project_EC2_instance[count.index].id
#   port        = 80
# }

resource "aws_lb" "base_project_alb" { // NLB for database is missing
  name               = terraform.workspace == "stg" ? "geacco-ALB-stg" : "geacco-ALB-prod"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ALB_security_group.id]
  subnets            = [for subnet in aws_subnet.base_project_cloud_subnet : subnet.id]
}

resource "aws_lb_listener" "base_project_alb_listener" {
  load_balancer_arn = aws_lb.base_project_alb.arn
  port              = "80"
  protocol          = "HTTP"

  # default_action {
  #   type = "redirect"

  #   redirect {
  #     port        = "443"
  #     protocol    = "HTTPS"
  #     status_code = "HTTP_301"
  #   }
  # }

  default_action {
    target_group_arn = "${aws_lb_target_group.base_project_alb_target_group.id}"
    type             = "forward"
  }
}

# resource "aws_lb_listener" "base_project_webservice_https" {
#   load_balancer_arn = aws_lb.base_project_alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = "arn:aws:acm:us-east-1:805389546304:certificate/2b2dae1d-71ce-4c26-a766-590a72892ae6"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.base_project_alb_target_group.id
#   }
# }

resource "aws_ecs_cluster" "base_project_ecs_cluster" {
  name = terraform.workspace == "stg" ? "base-project-ecs-cluster-stg" : "base-project-ecs-cluster-prod"
}

resource "aws_ecs_task_definition" "base_project_ecs_task_definition" {
  family                   = terraform.workspace == "stg" ? "base-project-image-stg" : "base-project-image-prod"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.base_project_ecs_execution_iam_role.arn
  requires_compatibilities = ["EC2"]
  memory                   = "1024"
  cpu                      = "512"
  # volume {
  #             name = "socket_volume"
  #         }
  volume {
              name = "static_volume"
          }

  container_definitions = jsonencode([
    {
      essential   = true
      memory      = 256
      name        = terraform.workspace == "stg" ? "base-project-image-stg" : "base-project-image-prod"
      cpu         = 256
      # entryPoint = ["/"],
      image       = "${var.REPOSITORY_URL}:${var.IMAGE_TAG}"
      environment = [
      {
        name  = "DEBUG",
        value = "on"
      },
      # {
      #   name  = "DATABASE_URL",
      #   value = "postgres://geaccousername:password@geaccodbprod.cg0exh01flwc.us-east-1.rds.amazonaws.com:5432/geacco_db_prod"
      # },
      {
        name  = "DATABASE_URL",
        value = "postgres://geaccousername:password@${aws_db_instance.geacco_db_instance.address}:${aws_db_instance.geacco_db_instance.port}/${aws_db_instance.geacco_db_instance.db_name}" //Change to secret manager
      },
      {
        name  = "SECRET_KEY",
        value = "0h7@rhy%nzmm*6rjz--%631e4tqji@m9q-tk@c!2fdir%vu9y-" //Change to secret manager
      },
      # {
      #   name  = "REDIS_URL",
      #   value = "redis://redis-cluster.cpeuty.ng.0001.use1.cache.amazonaws.com:6379/0"
      # },
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
      },
      {
        name  = "DJANGO_SUPERUSER_PASSWORD",
        value = "${var.DJANGO_SUPERUSER_PASSWORD}"
      },
      {
        name  = "DJANGO_SUPERUSER_USERNAME",
        value = "${var.DJANGO_SUPERUSER_USERNAME}"
      },
      {
        name  = "DJANGO_SUPERUSER_EMAIL",
        value = "${var.DJANGO_SUPERUSER_EMAIL}"
      }
      ],
      #command = ["alembic", "upgrade", "head"]
      #command = ["python3", "manage.py", "migrate"]
      # command = ["python3", "manage.py", "cities_light"]
      #command = ["make", "setup_environment"]
      #command = ["make", "test_sh"]
      #command = ["export", "DATABASE_URL=postgres://geaccousername:password@geaccodbprod.ciutmnlgyney.us-east-1.rds.amazonaws.com:5432/geacco_db_prod"],
      # command = [
      #       "python3",
      #       "manage.py",
      #       "createsuperuser",
      #       "--noinput",
      #       "--username",
      #       "jorge.salinas",
      #       "--email",
      #       "jorge.salinas@example.com"
      #   ],
      # command = var.DJANGO_SUPERUSER_USERNAME == "" ? [] : [
      #   "python3",
      #   "manage.py",
      #   "createsuperuser",
      #   "--noinput",
      #   "--username",
      #   "${var.DJANGO_SUPERUSER_USERNAME}",
      #   "--email",
      #   "${var.DJANGO_SUPERUSER_EMAIL}",
      # ]
      mountPoints = [
          # {
          #     "sourceVolume": "socket_volume",
          #     "containerPath": "/app/run",
          #     "readOnly": false
          # },
          {
              "sourceVolume": "static_volume",
              "containerPath": "/app/static",
              "readOnly": false
          }
      ],
      portMappings = [
        {
          containerPort = 8002,
          hostPort      = 8002,
          protocol      = "tcp"
        }
      ],
      entryPoint = ["/app/setup_environment"],
      logConfiguration = {
          logDriver = "awslogs",
          options = {
            awslogs-group = "base_project_image_logs",
            awslogs-create-group = "true", //Not taken as bool
            awslogs-region = "us-east-1",
            awslogs-stream-prefix = "ecs",
          }
      },
    },
    {
      essential   = true
      memory      = 257
      name        = terraform.workspace == "stg" ? "base-project-ngix-image-stg" : "base-project-ngix-image-prod"
      cpu         = 256
      # entryPoint = ["/"],
      image       = "${var.REPOSITORY_URL_NGINX}:${var.IMAGE_TAG_NGINX}"
    #   environment = [
    #   {
    #     name  = "DEBUG",
    #     value = "on"
    #   },
    #   # {
    #   #   name  = "DATABASE_URL",
    #   #   value = "postgres://geaccousername:password@geaccodbprod.cg0exh01flwc.us-east-1.rds.amazonaws.com:5432/geacco_db_prod"
    #   # },
    #   {
    #     name  = "DATABASE_URL",
    #     value = "postgres://geaccousername:password@${aws_db_instance.geacco_db_instance.address}:${aws_db_instance.geacco_db_instance.port}/${aws_db_instance.geacco_db_instance.db_name}" //Change to secret manager
    #   },
    #   {
    #     name  = "SECRET_KEY",
    #     value = "0h7@rhy%nzmm*6rjz--%631e4tqji@m9q-tk@c!2fdir%vu9y-" //Change to secret manager
    #   },
    #   # {
    #   #   name  = "REDIS_URL",
    #   #   value = "redis://redis-cluster.cpeuty.ng.0001.use1.cache.amazonaws.com:6379/0"
    #   # },
    #   {
    #     name  = "REDIS_URL",
    #     value = "redis://${aws_elasticache_replication_group.base_project_EC_replication_group.primary_endpoint_address}:6379/0"
    #   },
    #   {
    #     name  = "POSTGRES_PASSWORD",
    #     value = "password" //Change to secrets manager
    #   },
    #   {
    #     name  = "ENV",
    #     value = "build"
    #   }
    # ],
      #command = ["alembic", "upgrade", "head"]
      #command = ["make", "setup_environment"]
      #command = ["make", "test_sh"]
      #command = ["export", "DATABASE_URL=postgres://geaccousername:password@geaccodbprod.ciutmnlgyney.us-east-1.rds.amazonaws.com:5432/geacco_db_prod"],
      volumesFrom = [
      {
          sourceContainer = terraform.workspace == "stg" ? "base-project-image-stg" : "base-project-image-prod",
          readOnly = false
      }
      ]
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
            awslogs-group = "base_project_nginx_image_logs",
            awslogs-create-group = "true", //Not taken as bool
            awslogs-region = "us-east-1",
            awslogs-stream-prefix = "ecs",
          }
      },
    }
  ])
}




resource "aws_iam_role" "base_project_ecs_execution_iam_role" {
  name               = terraform.workspace == "stg" ? "base-project-ecs-task-role-stg" : "base-project-ecs-task-role-prod"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_execution_role.json
}


resource "aws_iam_role_policy_attachment" "base_project_ecs_task_role_policy_attachment" {
  count = length(var.iam_policy_arn_task_ecs)
  role  = aws_iam_role.base_project_ecs_execution_iam_role.name
  #policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerServiceforEC2Role"
  #policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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

  # statement {
  #   actions = ["sts:AssumeRole"]

  #   principals {
  #     type        = "Service"
  #     identifiers = ["ecs-tasks.amazonaws.com"]
  #   }

  #   condition {
  #     test     = "StringEquals"
  #     variable = "sts:ExternalId"
  #     values   = [
  #       "ecs.capability.ecr-auth",
  #       "ecs.capability.execution-role-ecr-pull",
  #       "ecs.capability.docker-remote-api.1.18",
  #       "ecs.capability.task-eni",
  #       "ecs.capability.docker-remote-api.1.29",
  #       "ecs.capability.logging-driver.awslogs",
  #       "ecs.capability.execution-role-awslogs",
  #       "ecs.capability.docker-remote-api.1.19",
  #       "ecs.capability.task-iam-role"
  #     ]
  #   }
  # }
}

resource "aws_ecs_service" "base_project_ecs_service" {
  depends_on           = [aws_lb_listener.base_project_alb_listener]
  name                 = terraform.workspace == "stg" ? "base-project-ecs-service-stg" : "base-project-ecs-service-prod"
  #deployment_circuit_breaker Add this later

  launch_type          = "EC2"
  cluster              = aws_ecs_cluster.base_project_ecs_cluster.id
  force_new_deployment = true
  task_definition      = aws_ecs_task_definition.base_project_ecs_task_definition.arn
  #desired_count   = 2
  desired_count = 2
  deployment_maximum_percent = 150
  deployment_minimum_healthy_percent = 50

  load_balancer {
    target_group_arn = aws_lb_target_group.base_project_alb_target_group.arn
    #container_name   = "base_project_image"
    container_name   = terraform.workspace == "stg" ? "base-project-ngix-image-stg" : "base-project-ngix-image-prod"
    container_port   = 8001
  }

  network_configuration {
    subnets            = [for subnet in aws_subnet.base_project_cloud_subnet : subnet.id]
    #assign_public_ip = true // Might not be neccesary
    security_groups = [aws_security_group.ECS_security_group.id]
  }
}

resource "aws_security_group" "ECS_security_group" {
  name        = terraform.workspace == "stg" ? "ECS_security_group_stg" : "ECS_security_group_prod"
  description = "A security group for the ECS"
  vpc_id      = aws_vpc.base_project_VPC.id


  # EC2 instances should be accessible anywhere on the internet via HTTP.
  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = "8001"
    to_port     = "8001"
    protocol    = "tcp"
    #cidr_blocks = ["0.0.0.0/0"]
    security_groups = [
      "${aws_security_group.ALB_security_group.id}",
    ]
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
    Name = terraform.workspace == "stg" ? "geacco_app_ecs_security_group_stg" : "geacco_app_ecs_security_group_prod"
  }
}
