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
# Install Certificates to Security Docker Socket
###############################################################################
resource "null_resource" "install_certificates" {
  count = "${length(var.ipv4_addresses)}"

  connection {
    type        = "ssh"
    user        = "${var.ssh_username}"
    private_key = "${var.ssh_private_key}"
    host        = "${var.ipv4_addresses[count.index]}"
  }

  provisioner "file" {
    content     = "${var.ca_crt}"
    destination = "/tmp/ca.crt"
  }

  provisioner "file" {
    content     = "${var.server_crt}"
    destination = "/tmp/server.crt"
  }

  provisioner "file" {
    content     = "${var.server_key}"
    destination = "/tmp/server.key"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/ca.crt /root/ca.crt",
      "sudo mv /tmp/server.crt /root/server.crt",
      "sudo mv /tmp/server.key /root/server.key"
    ]
  }

  depends_on = [
    null_resource.waited_on
  ]
}

###############################################################################
# Configure Salt & Apply Role
###############################################################################
# Migrate Grains
module "migrate_grains" {
  source = "git@gitlab.com:prairie-code-iac-recipes/salt-configuration.git//src/modules/migrate_grains"

  hosts           = "${var.ipv4_addresses}"
  role            = "${var.role}"
  ssh_username    = "${var.ssh_username}"
  ssh_private_key = "${var.ssh_private_key}"
}

# Install Minion
resource "null_resource" "configure_salt" {
  count = "${length(var.ipv4_addresses)}"

  connection {
    type        = "ssh"
    user        = "${var.ssh_username}"
    private_key = "${var.ssh_private_key}"
    host        = "${var.ipv4_addresses[count.index]}"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eou pipefail",
      "curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com",
      "chmod +x /tmp/bootstrap-salt.sh",
      "sudo /tmp/bootstrap-salt.sh -D -A ${var.saltmaster_internal}",
      "rm /tmp/bootstrap-salt.sh",
    ]
  }

  depends_on = [
    null_resource.install_certificates
  ]
}

resource "null_resource" "accept_key" {
  connection {
    type        = "ssh"
    user        = "${var.ssh_username}"
    private_key = "${var.ssh_private_key}"
    host        = "${var.saltmaster_external}"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eou pipefail",
      "sudo salt-key -A -y"
    ]
  }

  depends_on = [
    null_resource.configure_salt
  ]
}

resource "null_resource" "apply_states" {
  connection {
    type        = "ssh"
    user        = "${var.ssh_username}"
    private_key = "${var.ssh_private_key}"
    host        = "${var.saltmaster_external}"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eou pipefail",
      "sudo salt -G 'roles:${var.role}' test.ping",
      "sudo salt -t 60 -G 'roles:${var.role}' state.apply"
    ]
  }

  depends_on = [
    null_resource.accept_key
  ]
}
