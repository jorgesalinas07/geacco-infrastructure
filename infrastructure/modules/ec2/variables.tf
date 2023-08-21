variable "ec2_name" {
  type        = string
  description = "Name of the subnet to create"
}

variable "vpc_id" {
  type        = string
  description = "Id of the VPC to deploy on"
}

variable "subnet_count" {
  description = "Number of subnet"
  type        = map(number)
  default = {
    db_private    = 2 // Deployment requirement
    cloud_private = 2 // In case one of the subnets goes down for whatever reason, your site is still up and running
    EC_private    = 2
  }
}

variable "cloud_subnet_cidr_block" {
  description = "Available CIDR blocks for subnets"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
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
      engine_version      = "13.11"
      instance_class      = "db.t3.micro" //db.t3 – burstable-performance instance classes
      skip_final_snapshot = true
    },
    "web_app" = {
      count         = 1
      instance_type = "t3.xlarge"
    }
  }
}