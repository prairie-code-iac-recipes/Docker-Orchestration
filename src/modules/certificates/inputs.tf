variable "certificate_cn" {
  type        = string
  description = "Subject Common Name to be included in certificate being requested."
}

variable "country" {
  type        = string
  description = "Country to be included in the subject of the certificate."
}

variable "dns_names" {
  type        = list
  description = "List of DNS names for which a certificate is being requested."
}

variable "ip_addresses" {
  type        = list
  description = "List of IP addresses for which a certificate is being requested."
}

variable "locality" {
  type        = string
  description = "City to be included in the subject of the certificate."
}

variable "organization" {
  type        = string
  description = "Organization to be included in the subject of the certificate."
}

variable "province" {
  type        = string
  description = "State to be included in the subject of the certificate."
}

variable "wait_on" {
  type = list
  default = []
  description = "This module will wait for any resources listed to complete before it starts executing."
}
