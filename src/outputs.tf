output "DOCKER_CA_CRT" {
  description = "This is the public certificate for the certificate authority that generated the public/private keys used to secure the Docker socket from both a client and server perspective."
  value       = "${base64encode(module.certificates.ca_crt)}"
}

output "DOCKER_CLIENT_CRT" {
  description = "This is the public key used by the client to connect to the secured Docker socket."
  value = "${base64encode(module.certificates.client_crt)}"
}

output "DOCKER_CLIENT_KEY" {
  description = "This is the public key used by the client to connect to the secured Docker socket."
  value       = "${base64encode(module.certificates.client_key)}"
  sensitive   = true
}
