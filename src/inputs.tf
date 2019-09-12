variable "CI_API_V4_URL" {
  type        = string
  description = "This is the base URL for the Gitlab API."
}

variable "CI_COMMIT_SHORT_SHA" {
  type        = string
  description = "This is the first eight characters of the commit revision for which the project is being built."
}

variable "GITLAB_TOKEN" {
  type        = string
  description = "This is a personal access token used to authenticate to the Gitlab API."
}

variable "ssh_private_key" {
  type        = string
  description = "The contents of a base64-encoded SSH key to use for the connection."
}

variable "ssh_username" {
  type        = string
  description = "The user that we should use for the connection."
}
