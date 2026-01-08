variable "aws_region" {
  type = string
}

variable "name" {
  type = string
}

variable "k8s_version" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "vpc_cidr" {
  type = string
}

variable "enable_nat_gateway" {
  type = bool
}

variable "cluster_endpoint_public_access" {
  type = bool
}

variable "cluster_endpoint_private_access" {
  type = bool
}

variable "instance_types" {
  type = list(string)
}
variable "node_group" {
  type = object({
    desired_size   = number
    min_size       = number
    max_size       = number
    instance_types = list(string)
    capacity_type  = string
    disk_size      = number
  })
}
