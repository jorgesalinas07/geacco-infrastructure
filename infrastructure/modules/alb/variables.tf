variable "create_security_group" {
  type        = bool
  description = "Whether to create a security group or not"
  default     = false
}

variable "security_group_name" {
  type        = string
  description = "Name of the security group created"
}

variable "security_group_description" {
  type        = string
  description = "Description of the security group created"
}

variable "vpc_id" {
  type        = string
  description = "Id of the vpc to create the security group under"
}

variable "my_ip" {
  type        = string
  description = "IP of computer to ssh from"
}

variable "create_lb_target_group" {
  type        = bool
  description = "Whether to create a lg target group or not"
  default     = false
}

variable "lb_target_group_name" {
  type        = string
  description = "Name of the lb security group created"
}

variable "lb_target_group_port" {
  type        = number
  description = "port number of the lb security group created"
  default     = 8001
}

variable "lb_target_group_target_type" {
  type        = string
  description = "Type of targe for the lb target group"
  default     = "ip"
}

variable "lb_target_group_target_protocol" {
  type        = string
  description = "Protocol of targe for the lb target group"
  default     = "HTTP"
}

variable "deregistration_delay" {
  type        = number
  description = "Amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused"
  default     = 5 // Not so sure *** The range is 0-3600 seconds
}

variable "lb_target_group_health_check_path" {
  type        = string
  description = "Destination for the health check request. "
  default     = "/health"
}

variable "lb_target_group_health_check_healthy_threshold" {
  type        = number
  description = "Number of consecutive health check successes required before considering a target healthy"
  default     = 2 // Not so sure *** The range is 2-10. Defaults to 3.
}

variable "lb_target_group_health_check_interval" {
  type        = number
  description = "Approximate amount of time, in seconds, between health checks of an individual target."
  default     = 2 // Not so sure ***  The range is 5-300. 
}

variable "lb_target_group_health_check_timeout" {
  type        = number
  description = "Amount of time, in seconds, during which no response from a target means a failed health check."
  default     = 2 // Not so sure *** The range is 2–120 seconds
}

variable "lb_name" {
  type        = string
  description = "Name of load balancer"
}

variable "lb_internal" {
  type        = bool
  description = "If true, the LB will be internal."
  default     = false
}

variable "load_balancer_type" {
  type        = string
  description = "The type of load balancer to create"
}

variable "lb_security_groups" {
  type        = list(any)
  description = "A list of security group IDs to assign to the LB"
}

variable "lb_subnets" {
  type        = list(any)
  description = "A list of subnets IDs attached to the LB"
}

variable "lb_listener_port" {
  type        = number
  description = "Port number for lb to listen at"
  default     = 80
}

variable "lb_listener_protocol" {
  type        = string
  description = "Protocol for lb to listen"
  default     = "HTTP"
}
