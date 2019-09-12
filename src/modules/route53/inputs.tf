variable "app_domains" {
  type        = list
  description = "List of app domains to be routed to the Docker Swarm cluster."
}

variable "app_zone_ids" {
  type        = list
  description = "The AWS-assigned ID of the hosted zone to contain the DNS records for the app domains."
}

variable "name_tag" {
  type        = string
  description = "This value will be assigned to the name tag."
}

variable "ipv4_addresses" {
  type        = list
  description = "List of AWS-assigned public IP addresses."
}

variable "manager_count" {
  type        = number
  description = "The number of instances to be associated with the Docker Swarm manager DNS name."
}

variable "primary_domain" {
  type        = string
  description = "The primary domain to be associated with all Docker Swarm DNS names registered."
}

variable "primary_zone_id" {
  type        = string
  description = "The AWS-assigned ID of the hosted zone to contain the DNS record for the provisioned server(s)."
}

variable "wait_on" {
  type = list
  default = []
  description = "This module will wait for any resources listed to complete before it starts executing."
}
