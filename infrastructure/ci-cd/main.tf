terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.9.0"
    }

    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket  = "geacco-app-tfstate-79eb25"
    key     = "global/s3/geacco-app-ci-cd.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "geacco-app-tfstate-79eb25"
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption_configuration" {
  bucket = aws_s3_bucket.terraform_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_user" "backend-user" {
  name = "geacco-app-ci-cd-user"
}

resource "aws_iam_access_key" "backend_user_api_access" {
  user = aws_iam_user.backend-user.name
}


resource "aws_iam_user_policy" "backend_user_inline_policy" {
  name = "geacco-app-ci-cd-policy"
  user = aws_iam_user.backend-user.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53domains:*",
                "ecr:BatchGetImage",
                "ecr:GetRepositoryPolicy",
                "ecr:SetRepositoryPolicy",
                "ecr:BatchCheckLayerAvailability",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeImages",
                "ecr:DescribeRepositories",
                "ecr:GetDownloadUrlForLayer",
                "ecr:InitiateLayerUpload",
                "ecr:ListImages",
                "ecr:PutImage",
                "ecr:UploadLayerPart",
                "ecr:GetAuthorizationToken",
                "ecr:ListTagsForResource",
                "ecr:GetLifecyclePolicy",
                "s3:ListBucket",
                "s3:GetBucketVersioning",
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:GetObjectVersion",
                "iam:CreateRole",
                "iam:PutRolePolicy",
                "iam:PassRole",
                "iam:GetRole",
                "iam:ListRolePolicies",
                "iam:GetRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:GetRepositoryPolicy",
                "iam:SetRepositoryPolicy",
                "iam:ListInstanceProfilesForRole",
                "iam:DeleteRolePolicy",
                "iam:DeleteRole",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:CreateLogDelivery"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
