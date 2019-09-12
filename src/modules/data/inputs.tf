variable "ami_name" {
  type        = string
  description = "The name of the AMI as displayed in the AWS Management Console."
}

variable "app_domains" {
  type        = list
  description = "List of app domains that zone information should be retrieved for."
}

variable "availability_zones" {
  type        = list
  description = "List of availablibility zones within the VPC listed above that subnet information should be retrieved for."
}

variable "primary_domain" {
  type        = string
  description = "The primary domain that zone information should be retrieved for."
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block associated with the VPC you want to lookup."
}
