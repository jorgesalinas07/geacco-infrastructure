variable "bucket_name" {
  type        = string
  description = "Name for the bucket created"
}

variable "bucket_versioning_status" {
  type        = string
  description = "Versioning state of the bucket"
  default     = "Enabled"
}

variable "bucket_encryption_sse_algorithm" {
  type        = string
  description = " Server-side encryption algorithm to use"
  default     = "AES256"
}

variable "bucket_security_group_vpc_id" {
  type        = string
  description = "Vpc for the s3 bucket security group"
}

variable "bucket_security_groups" {
  type        = list
  description = "List of bucket security groups"
}

variable "aws_region" {
  type        = string
  description = "Aws region to deploy"
}

variable "endpoint_route_table" {
  type        = string
  description = "Endpoint route table association id"
}

