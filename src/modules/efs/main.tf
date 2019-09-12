locals {
    efs_mount_target         = "/mnt/efs"
    security_group_rules = [
    {
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["${var.vpc_cidr_block}"]
    },
    {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
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
# Security Group for EFS Share Drive
###############################################################################
resource "aws_security_group" "default" {
  name                   = "${var.name_tag}-efs"
  vpc_id                 = "${var.vpc_id}"

  tags = {
    Group                = "${var.group_tag}"
    Description          = "${var.description_tag}"
  }
}

resource "aws_security_group_rule" "default" {
  count             = "${length(local.security_group_rules)}"

  type              = "${local.security_group_rules[count.index]["type"]}"
  from_port         = "${local.security_group_rules[count.index]["from_port"]}"
  to_port           = "${local.security_group_rules[count.index]["to_port"]}"
  protocol          = "${local.security_group_rules[count.index]["protocol"]}"
  cidr_blocks       = "${local.security_group_rules[count.index]["cidr_blocks"]}"

  security_group_id = "${aws_security_group.default.id}"
}

###############################################################################
# Provision Shared NFS File Server for Docker Swarm
###############################################################################
resource "aws_efs_file_system" "default" {
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name        = "${var.name_tag}"
    Description = "${var.description_tag}"
    Group       = "${var.group_tag}"
  }
}

resource "aws_efs_mount_target" "default" {
  count = "${length(var.subnet_ids)}"

  file_system_id  = "${aws_efs_file_system.default.id}"
  security_groups = ["${aws_security_group.default.id}"]
  subnet_id       = "${var.subnet_ids[count.index]}"
}

###############################################################################
# Mount EFS on Docker Instances as Shared Storage
###############################################################################
resource "null_resource" "mount_efs" {
  count = "${length(aws_efs_mount_target.default.*.dns_name) > 0 ? length(var.ipv4_addresses) : 0}"

  connection {
    type        = "ssh"
    user        = "${var.ssh_username}"
    private_key = "${var.ssh_private_key}"
    host        = "${element(var.ipv4_addresses, count.index)}"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eou pipefail",
      "sudo mkdir -p ${local.efs_mount_target}",
      "sudo cp /etc/fstab /etc/fstab.backup",
      "sudo chown ${var.ssh_username}:${var.ssh_username} /etc/fstab",
      "sudo echo ${element(aws_efs_mount_target.default.*.dns_name, count.index + 1 % length(aws_efs_mount_target.default.*.dns_name))}:/ ${local.efs_mount_target} nfs nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0 >> /etc/fstab",
      "sudo chown root:root /etc/fstab",
      "sudo mount -a",
      "sudo chown ${var.ssh_username}:${var.ssh_username} ${local.efs_mount_target}"
    ]
  }

  provisioner "remote-exec" {
    when   = "destroy"
    inline = [
      "set -eou pipefail",
      "sudo umount ${local.efs_mount_target} || true",
      "sudo rm -rf ${local.efs_mount_target}",
      "sudo rm /etc/fstab",
      "sudo mv /etc/fstab.backup /etc/fstab"
    ]
  }

  depends_on = [
    null_resource.waited_on
  ]
}
