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
  port        = 8001
  target_type = "ip"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.base_project_VPC.id
  deregistration_delay = 5// Not so sure

  lifecycle { create_before_destroy=true }

  health_check {
  #   path = "/api/1/resolve/default?path=/service/my-service"
    port = 8001
    path = "/docs"
    healthy_threshold = 2 // Not so sure
  #   unhealthy_threshold = 2
  #   timeout = 2
    interval = 5// Not so sure
    timeout = 2// Not so sure
  #   matcher = "200"  # has to be HTTP 200 or fails
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

# resource "aws_lb_listener_rule" "base_project_alb_listener_rule" {
#   listener_arn = aws_lb_listener.base_project_alb_listener.arn
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.base_project_alb_target_group.arn
#   }

#   condition {
#     source_ip {
#       values = ["18.204.41.246/32"]
#     }
#   }
# }

# data "aws_iam_policy_document" "base_project_ecs_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "base_project_ecs_iam_role" {
#   name               = "base-project-ecs-iam-role"
#   assume_role_policy = data.aws_iam_policy_document.base_project_ecs_policy.json
# }


# resource "aws_iam_role_policy_attachment" "base_project_ecs_role_policy_attachment" {
#   role       = aws_iam_role.base_project_ecs_iam_role.name
#   #policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerServiceforEC2Role"
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
# }

# resource "aws_iam_instance_profile" "base_project_ecs_iam_profile" {
#   name = "base-project-ecs-iam-role"
#   role = aws_iam_role.base_project_ecs_iam_role.name
# }

# resource "aws_launch_configuration" "base_project_ecs_launch_config" {
#     image_id      = data.aws_ami.ecs_ami.id
#     # image_id             = "ami-094d4d00fd7462815" //Change to variable to ubuntu
#     iam_instance_profile = aws_iam_instance_profile.base_project_ecs_iam_profile.name
#     security_groups      = [aws_security_group.EC2_security_group.id]
#     #user_data            = "#!/bin/bash\necho ECS_CLUSTER=base-project-ecs-cluster >> /etc/ecs/ecs.config"
#     #user_data_base64       = filebase64("user_data2.sh")
#     user_data_base64            = filebase64("user_data.sh")
#     instance_type        = var.settings.web_app.instance_type
# }

# resource "aws_autoscaling_group" "base_project_autoscaling_group" {
#     depends_on = [
#       aws_lb.base_project_alb,
#     ]
#     health_check_grace_period = 120 // Might be too little or much
#     lifecycle {
#       create_before_destroy = true
#     }
#     # target_group_arns = [
#     #   aws_lb_target_group.base_project_alb_target_group.arn,
#     # ]

#     name                      = "base_project_autoscaling_group"
#     desired_capacity          = "2"
#     # vpc_zone_identifier       = [aws_subnet.pub_subnet.id]
#     vpc_zone_identifier = [for subnet in aws_subnet.base_project_cloud_subnet : subnet.id] //Change to only work with one zone
#     //  vpc_zone_identifier = [aws_subnet.base_project_cloud_subnet[0].id]
#     launch_configuration      = aws_launch_configuration.base_project_ecs_launch_config.name

#     termination_policies = [
#       "OldestInstance",
#       "OldestLaunchConfiguration",
#     ]


#     min_size                  = 2
#     max_size                  = 6
#     #health_check_grace_period = 300
#     health_check_type         = "ELB"
# }

# resource "aws_autoscaling_group" "base_project_autoscaling_group" {
#     name                      = "base_project_autoscaling_group"
#     # vpc_zone_identifier       = [aws_subnet.pub_subnet.id]
#     vpc_zone_identifier = [for subnet in aws_subnet.base_project_cloud_subnet : subnet.id]
#     launch_configuration      = aws_launch_configuration.base_project_ecs_launch_config.name

#     desired_capacity          = 2
#     min_size                  = 2
#     max_size                  = 10
#     health_check_grace_period = 120
#     health_check_type         = "EC2"
# }

resource "aws_ecs_cluster" "base_project_ecs_cluster" {
  name = "base-project-ecs-cluster"
}

resource "aws_ecs_task_definition" "base_project_ecs_task_definition" {
  family                   = "base_project_image"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.base_project_ecs_execution_iam_role.arn
  requires_compatibilities = ["EC2"]
  # memory                   = "1024"
  # cpu                      = "512"
  container_definitions = jsonencode([
    {
      essential   = true
      memory      = 256
      name        = "base_project_image"
      cpu         = 256
      # entryPoint = ["/"],
      image       = "${var.REPOSITORY_URL}:${var.IMAGE_TAG}"
      environment = []
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
  name               = "base_project_ecs_task_role"
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
}

resource "aws_ecs_service" "base_project_ecs_service" {
  depends_on           = [aws_lb_listener.base_project_alb_listener]
  name                 = "base_project_ecs_service"
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
    container_name   = "base_project_image"
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
