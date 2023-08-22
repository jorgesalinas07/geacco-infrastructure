resource "aws_secretsmanager_secret" "db_credential" {
   name = terraform.workspace == "stg" ? "db-credential-stg" : "db-credential-prod"
}

resource "aws_secretsmanager_secret_version" "db_credentials_secret_version" {
  secret_id = aws_secretsmanager_secret.db_credential.id
  secret_string = <<EOF
   {
    "username": "${var.db_username}",
    "password": "${var.db_password}"
   }
EOF
}

data "aws_secretsmanager_secret" "secretmasterDB" {
  arn = aws_secretsmanager_secret.db_credential.arn
}

data "aws_secretsmanager_secret_version" "creds" {
  secret_id = data.aws_secretsmanager_secret.secretmasterDB.arn
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)
}
