module "base_project_ECR" {
  source   = "../common/ecr"
  ecr_name = terraform.workspace == "stg" ? "geacco_app_stg" : "geacco_app_prod"
}

// Instance profile
resource "aws_iam_instance_profile" "base_project_repository_intance_profile" {
  role = aws_iam_role.base_project_repository_role.name
}

resource "aws_iam_role_policy_attachment" "base_project_repository_attachment" {
  role       = aws_iam_role.base_project_repository_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "base_project_repository_role" {
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
