variable "ec_name" {
  type        = string
  description = "Name for the elastic cache"
}

variable "vpc_id" {
  type        = string
  description = "Id of the security group vpc"
}

variable "ec_security_groups" {
  type        = list(any)
  description = "Id of the ingress rule security groups "
}

variable "replication_group_id" {
  type        = string
  description = "Id of the iec replication "
}

variable "node_type" {
  type        = string
  description = "Machine type for the replica"
  default     = "cache.t2.micro"
}

variable "port" {
  type        = number
  description = "Replaca port number"
  default     = 6379
}

variable "engine_version" {
  type        = string
  description = "ec engine version"
  default     = "5.0.6"
}

variable "num_node_groups" {
  type        = string
  description = "ec engine version"
  default     = "5.0.6"
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

variable "EC_subnet_cidr_block" {
  description = "Available CIDR blocks for subnets"
  type        = list(string)
  default = [
    "10.0.9.0/24",
    "10.0.10.0/24",
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

variable "subnet_id" {
  type        = string
  description = "Id of the subnet"
}