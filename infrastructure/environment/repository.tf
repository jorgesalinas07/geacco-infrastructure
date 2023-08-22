module "base_project_ECR" {
  source   = "../common/ecr"
  ecr_name = terraform.workspace == "stg" ? "geacco_app_stg" : "geacco_app_prod"
}

module "base_project_ECR_nginx" {
  source   = "../common/ecr"
  ecr_name = terraform.workspace == "stg" ? "geacco_app_nginx_stg" : "geacco_app_nginx_prod"
}

// Instance profile
resource "aws_iam_instance_profile" "base_project_repository_intance_profile" {
  role = aws_iam_role.base_project_repository_role.name
}

resource "aws_iam_role_policy_attachment" "base_project_repository_attachment" {
  count      = length(var.iam_policy_arn)
  policy_arn = var.iam_policy_arn[count.index]
  role       = aws_iam_role.base_project_repository_role.name
}

resource "aws_iam_role" "base_project_repository_role" {
  name               = terraform.workspace == "stg" ? "base-project-ec2-iam-role-stg" : "base-project-ec2-iam-role-prod"
  path               = "/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}
