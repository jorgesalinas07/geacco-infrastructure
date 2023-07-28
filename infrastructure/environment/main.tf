module "base_project_ECR" {
  source   = "../common/ecr"
  ecr_name = terraform.workspace == "stg" ? "geacco_app_stg" : "geacco_app_prod"
}
