variable  "ami" {
  type        = string
  description = "The AMI to use for the instance."
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Associate a public ip address with an instance in a VPC."
}

variable "availability_zones" {
  type        = list
  description = "The AZ to start the instance in. If instance_count is greater than 1 then each subsequent instance will be assigned to a subsequent availability zone."
}

variable "description_tag" {
  type        = string
  description = "This value will be assigned to the description tag."
}

variable "group_tag" {
  type        = string
  description = "This value will be assigned to the group tag."
}

variable "instance_count" {
  type        = number
  description = "The number of instances to create."
}

variable "instance_type" {
  type        = string
  description = "The type of instance to start. Updates to this field will trigger a stop/start of the EC2 instance."
}

variable "name_tag" {
  type        = string
  description = "This value will be assigned to the name tag."
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

variable "ssh_private_key" {
  type        = string
  description = "The contents of an SSH key to use for the connection."
}

variable "ssh_username" {
  type        = string
  description = "The user that we should use for the connection."
}

variable "starting_hostnum" {
  type        = number
  description = "The host number to assign to the first instance. If instance_count is greater than 1 then this number will be incremented for each subsequent instance."
}

variable "subnet_ids" {
  type        = list
  description = "A list of VPC subnet IDs to launch instances in. A round-robin approach is used to assign subnets to instances."
}

variable "subnet_cidrs" {
  type        = list
  description = "A list of VPC subnet CIDR blocks to assign IP addresses from. A round-robin approach is used to assign subnets to instances."
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

variable "whitelist_cidrs" {
  type        = list
  description = "This is the list of CIDR blocks that should be allowed to access the server(s) provisioned via SSH or ZeroMQ."
}
