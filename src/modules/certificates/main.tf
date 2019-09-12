###############################################################################
# Used to Enable Inter-Module Dependency
###############################################################################
resource "null_resource" "waited_on" {
  count = "${length(var.wait_on)}"

  provisioner "local-exec" {
    command = "echo Dependency ${count.index + 1} of ${length(var.wait_on)} Resolved: ${var.wait_on[count.index]}"
  }
}

###############################################################################
# Certificate Authority Key and Certificate
###############################################################################
resource "tls_private_key" "ca_key" {
  algorithm   = "RSA"
  rsa_bits = 4096

  depends_on = [
    null_resource.waited_on
  ]
}

resource "tls_self_signed_cert" "ca_crt" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.ca_key.private_key_pem}"
  subject {
    country             = "${var.country}"
    province            = "${var.province}"
    locality            = "${var.locality}"
    organization        = "${var.organization}"
    common_name         = "${var.certificate_cn}"

  }
  validity_period_hours = 43800
  allowed_uses          = [
    "key_encipherment",
    "digital_signature",
    "cert_signing"
  ]
  is_ca_certificate     = true
}

###############################################################################
# Server Key and Certificate
###############################################################################
resource "tls_private_key" "server_key" {
  algorithm   = "RSA"
  rsa_bits = 4096

  depends_on = [
    null_resource.waited_on
  ]
}
resource "tls_cert_request" "server_csr" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.server_key.private_key_pem}"
  subject {
    common_name   = "${var.certificate_cn}"
  }
  dns_names       = "${var.dns_names}"
  ip_addresses    = "${var.ip_addresses}"
}

resource "tls_locally_signed_cert" "server_crt" {
  cert_request_pem   = "${tls_cert_request.server_csr.cert_request_pem}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${tls_private_key.ca_key.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.ca_crt.cert_pem}"

  validity_period_hours = 43800

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}

###############################################################################
# Client Key and Certificate
###############################################################################
resource "tls_private_key" "client_key" {
  algorithm   = "RSA"
  rsa_bits = 4096

  depends_on = [
    null_resource.waited_on
  ]
}

resource "tls_cert_request" "client_csr" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.client_key.private_key_pem}"
  subject {
    common_name  = "client"
  }
}

resource "tls_locally_signed_cert" "client_crt" {
  cert_request_pem   = "${tls_cert_request.client_csr.cert_request_pem}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${tls_private_key.ca_key.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.ca_crt.cert_pem}"

  validity_period_hours = 43800

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth"
  ]
}
