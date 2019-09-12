variable "manager_count" {
  type        = number
  description = "The number of instances to configure as Docker Swarm managers."
}

variable "private_ips" {
  type        = list
  description = "IP addresses of instances to configure Docker Swarm on.  This is used to communicate internally between managers and workers."
}

variable "public_ips" {
  type        = list
  description = "IP addresses of instances to configure Docker Swarm on.  This is used to connect via SSH."
}

variable "ssh_private_key" {
  type        = string
  description = "The contents of an SSH key to use for the connection."
}

variable "ssh_username" {
  type        = string
  description = "The user that we should use for the connection."
}

variable "wait_on" {
  type = list
  default = []
  description = "This module will wait for any resources listed to complete before it starts executing."
}
