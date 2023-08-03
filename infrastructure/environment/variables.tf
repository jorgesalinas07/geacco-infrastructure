variable "IMAGE_TAG" {
  description = "ECR Image tag"
  type        = string
  default     = "latest"
}

variable "subnet_count" {
  description = "Number of subnet"
  type        = map(number)
  default = {
    db_private    = 2
    cloud_private = 1
  }
}

variable "my_ip" {
  description = "Master Ip Address"
  type        = string
  sensitive   = true
}

variable "settings" {
  description = "Configuration settings"
  type        = map(any)
  default = {
    "database" = {
      allocated_storage   = 10
      engine              = "postgres"
      engine_version      = "14.3"
      instance_class      = "db.t2.micro"
      skip_final_snapshot = true
    },
    "web_app" = {
      count         = 1
      instance_type = "t2.micro"
    }
  }
}

variable "db_username" {
  description = "Database master user"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master user password"
  type        = string
  sensitive   = true
}

variable "subnet_cidr_block" {
  description = "Available CIDR blocks for subnets"
  type        = string
  default     = "10.0.1.0/24"
}

variable "aws_region" {
  description = "Aws region"
  type        = string
}
