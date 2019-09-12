locals {
  temp_dir = "/tmp"
}

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
# Use First Server to Initialize Swarm
###############################################################################
data "external" "swarm_init" {
  program       = ["bash", "${path.module}/scripts/swarm_init.sh"]

  query = {
    working_dir = "${local.temp_dir}"
    user        = "${var.ssh_username}",
    ssh_host    = "${var.public_ips[0]}"
    docker_host = "${var.private_ips[0]}"
    private_key = "${base64encode(var.ssh_private_key)}"
  }

  depends_on = [
    null_resource.waited_on
  ]
}

###############################################################################
# Join Additional Managers to Swarm
###############################################################################
resource "null_resource" "swarm_manager_registration" {
  count = "${var.manager_count - 1}"

  connection {
    type        = "ssh"
    user        = "${var.ssh_username}"
    private_key = "${var.ssh_private_key}"
    host        = "${var.public_ips[count.index + 1]}"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eou pipefail",
      "docker swarm leave --force || true",
      "docker swarm join --token ${lookup(data.external.swarm_init.result, "manager")}"
    ]
  }
}

###############################################################################
# Join Workers to Swarm
###############################################################################
resource "null_resource" "swarm_worker_registration" {
  # Ternary Required on Destroy When Failure Occurs Half-Way Through
  count = "${length(var.public_ips) > var.manager_count ? length(var.public_ips) - var.manager_count : 0}"

  connection {
    type        = "ssh"
    user        = "${var.ssh_username}"
    private_key = "${var.ssh_private_key}"
    host        = "${var.public_ips[count.index + var.manager_count]}"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eou pipefail",
      "docker swarm leave --force || true",
      "docker swarm join --token ${lookup(data.external.swarm_init.result, "worker")}"
    ]
  }
}
