output "ca_crt" {
  value = "${tls_self_signed_cert.ca_crt.cert_pem}"
}

output "ca_key" {
  value = "${tls_private_key.ca_key.private_key_pem}"
  sensitive = true
}

output "client_crt" {
  value = "${tls_locally_signed_cert.client_crt.cert_pem}"
}

output "client_key" {
  value = "${tls_private_key.client_key.private_key_pem}"
  sensitive = true
}

output "server_crt" {
  value = "${tls_locally_signed_cert.server_crt.cert_pem}"
}

output "server_key" {
  value = "${tls_private_key.server_key.private_key_pem}"
  sensitive = true
}

output "wait_on" {
  description = "This output can be passed in another module's waited_on input to force an inter-module dependency."
  value       = "CA, Server, and Client Certificates Created"
  depends_on  = [
    tls_locally_signed_cert.server_crt,
    tls_locally_signed_cert.client_crt
  ]
}
