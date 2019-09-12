
variable "ca_crt" {
  type        = string
  description = "The certificate authority's certificate data in PEM format. Used to secure the Docker socket."
}

variable "role" {
  type        = string
  description = "Server Role"
}

variable "saltmaster_external" {
  type        = string
  description = "Externally resolvable DNS name or IP address of a saltmaster."
}

variable "saltmaster_internal" {
  type        = string
  description = "Internally resolvable DNS name or IP address of a saltmaster."
}

variable "server_crt" {
  type        = string
  description = "The certificate data in PEM format. Used to secure the Docker socket."
}

variable "server_key" {
  type        = string
  description = "The private key data in PEM format. Used to secure the Docker socket."
}

variable "ssh_private_key" {
  type        = string
  description = "The contents of an SSH key to use for the connection."
}

variable "ssh_username" {
  type        = string
  description = "The user that we should use for the connection."
}

variable "ipv4_addresses" {
  type        = list
  description = "List of AWS-assigned public IP addresses."
}

variable "wait_on" {
  type = list
  default = []
  description = "This module will wait for any resources listed to complete before it starts executing."
}

