variable "subnet_count" {
  description = "Number of subnet"
  type        = map(number)
  default = {
    db_private    = 2 // Deployment requirement
    cloud_private = 2 // In case one of the subnets goes down for whatever reason, your site is still up and running
    EC_private    = 2
  }
}

variable "vpc_id" {
  type        = string
  description = "Id for the subnet vpc"
}

variable "db_subnet_cidr_block" {
  description = "Available CIDR blocks for subnets"
  type        = list(string)
  default = [
    "10.0.5.0/24",
    "10.0.6.0/24",
    "10.0.7.0/24",
    "10.0.8.0/24"
  ]
}

variable "db_name" {
  type        = string
  description = "Name for the database"
}

variable "ingress_security_groups" {
  type        = list(any)
  description = "list of security groups with access to the db"
}

variable "settings" {
  description = "Configuration settings"
  type        = map(any)
  default = {
    "database" = {
      allocated_storage   = 10
      engine              = "postgres"
      engine_version      = "13.11"
      instance_class      = "db.t3.micro" //db.t3 – burstable-performance instance classes
      skip_final_snapshot = true
    },
    "web_app" = {
      count = 1
      #instance_type = "t2.medium"
      instance_type = "t3.xlarge"
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
