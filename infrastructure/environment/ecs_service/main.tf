module "elastic_cache" {
  source = "../../modules/ecs"
  ecs_cluster_name = "base-project-ecs-cluster"
  iam_role_name = "base_project_ecs_task_role"
  ecs_service_name = "base_project_ecs_service"
  load_balancer_container_name = "base_project_image"
}