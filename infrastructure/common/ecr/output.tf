output "ecr" {
  value = resource.aws_ecr_repository.ecr
}

output "ecr_uri" {
  value = resource.aws_ecr_repository.ecr.repository_url
}
