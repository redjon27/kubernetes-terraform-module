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

variable "instance_types" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "node_group" {
  description = "Managed node group sizing and config"
  type = object({
    desired_size = number
    min_size     = number
    max_size     = number
    instance_types = list(string)
    capacity_type  = string # ON_DEMAND or SPOT
    disk_size      = number
  })
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = true
}

variable "cluster_endpoint_private_access" {
  type    = bool
  default = true
}