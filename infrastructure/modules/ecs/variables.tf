variable "ecs_cluster_name" {
  type = string
  description = "Name for the ecs cluster"
}

variable "task_definition_family" {
  type = string
  description = "A unique name for your task definition."
  default = "base_project_image"
}

variable "task_definition_network_mode" {
  type = string
  description = "Docker networking mode to use for the containers in the task"
  default = "awsvpc"
}

variable "requires_compatibilities" {
  type = list
  description = "Set of launch types required by the task"
  default = ["EC2"]
}

variable "iam_role_name" {
  type = string
  description = "Name for the ecs iam role"
}

variable "ecs_service_name" {
  type = string
  description = "Name for the ecs service"
}

variable "ecs_service_launch_type" {
  type = string
  description = "Hot yhr ecs will be deployed"
  default = "EC2"
}

variable "iam_policy_arn_task_ecs" {
  description = "IAM Policy to be attached to ecs task role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
  ]
}

variable "ecs_force_new_deployment" {
  type = bool
  description = "Enable to force a new task deployment of the service"
  default = true
}

variable "load_balancer_container_name" {
  type = string
  description = "Name of the container to associate with the load balancer "
}
