variable "description_tag" {
  type        = string
  description = "This value will be assigned to the description tag."
}

variable "group_tag" {
  type        = string
  description = "This value will be assigned to the group tag."
}

variable "ipv4_addresses" {
  type        = list
  description = "List of AWS-assigned public IP addresses."
}

variable "name_tag" {
  type        = string
  description = "This value will be assigned to the name tag."
}

variable "ssh_private_key" {
  type        = string
  description = "The contents of an SSH key to use for the connection."
}

variable "ssh_username" {
  type        = string
  description = "The user that we should use for the connection."
}

variable "subnet_ids" {
  type        = list
  description = "A list of VPC subnet IDs to launch instances in. A round-robin approach is used to assign subnets to instances."
}

variable "vpc_cidr_block" {
  type        = string
  description = "This is the CIDR block to be assigned to the private VPC that will be peered to the OMNI-VPC."
}

variable "vpc_id" {
  type        = string
  description = "This is the AWS-assigned identifier for the VPC to be associated with the provisioned security group."
}

variable "wait_on" {
  type = list
  default = []
  description = "This module will wait for any resources listed to complete before it starts executing."
}
