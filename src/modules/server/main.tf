locals {
  security_group_rules = [
    {
      type        = "ingress"
      from_port   = "22"
      to_port     = "22"
      protocol    = "tcp"
      cidr_blocks = "${var.whitelist_cidrs}"
    },
    {
      type        = "ingress"
      from_port   = "80"
      to_port     = "80"
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "ingress"
      from_port   = "443"
      to_port     = "443"
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "ingress"
      from_port   = "2376"
      to_port     = "2377"
      protocol    = "tcp"
      cidr_blocks = "${var.whitelist_cidrs}"
    },
    {
      type        = "ingress"
      from_port   = "7946"
      to_port     = "7946"
      protocol    = "tcp"
      cidr_blocks = "${var.whitelist_cidrs}"
    },
    {
      type        = "ingress"
      from_port   = "7946"
      to_port     = "7946"
      protocol    = "udp"
      cidr_blocks = "${var.whitelist_cidrs}"
    },
    {
      type        = "ingress"
      from_port   = "4789"
      to_port     = "4789"
      protocol    = "udp"
      cidr_blocks = "${var.whitelist_cidrs}"
    },
    {
      type        = "ingress"
      from_port   = "0"
      to_port     = "0"
      protocol    = "50"
      cidr_blocks = "${var.whitelist_cidrs}"
    },
    {
      type        = "egress"
      from_port   = "0"
      to_port     = "0"
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

# #############################################################################
# The host offset external data provider is used to calculate host number
# offsets under the assumption that instances will be assigned to availability
# zone-specific subnets in a round-robin fashion.  The offset calculated will
# be added to some starting host number reflecting the first unassigned host
# number.
#
# Example:
# Starting Host Number: 4
# AZ #1 Subnet Host Numbers: Host 1 Assigned 4, Host 3 Assigned 5, etc...
# AZ #2 Subnet Host Numbers: Host 2 Assigned 4, Host 4 Assigned 5, etc...
# #############################################################################
data "external" "host_offset" {
  program = ["bash", "${path.module}/scripts/host-offset.sh"]

  query = {
    subnet_count   = "${length(var.subnet_cidrs)}"
    instance_count = "${var.instance_count}"
  }
}

###############################################################################
# Security Group for EC2 Instances
###############################################################################
resource "aws_security_group" "default" {
  name                   = "${var.name_tag}"
  vpc_id                 = "${var.vpc_id}"

  tags = {
    Group                = "${var.group_tag}"
    Description          = "${var.description_tag}"
  }

  depends_on = [
    null_resource.waited_on
  ]
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
# Instances
###############################################################################
resource "aws_iam_instance_profile" "default" {
  name = "${var.name_tag}"
  role = "${var.role}"

  depends_on = [
    null_resource.waited_on
  ]
}

resource "aws_instance" "default" {
  count                                = "${var.instance_count}"

  ami                                  = "${var.ami}"
  associate_public_ip_address          = "${var.associate_public_ip_address}"
  availability_zone                    = "${element(var.availability_zones, count.index + 1 % length(var.availability_zones))}"
  iam_instance_profile                 = "${aws_iam_instance_profile.default.name}"
  instance_type                        = "${var.instance_type}"
  private_ip                           = "${cidrhost(element(var.subnet_cidrs, count.index + 1 % length(var.subnet_cidrs)), lookup(data.external.host_offset.result, count.index) + var.starting_hostnum)}"
  subnet_id                            = "${element(var.subnet_ids, count.index + 1 % length(var.subnet_ids))}"
  vpc_security_group_ids               = ["${aws_security_group.default.id}"]

  tenancy                              = "default"
  instance_initiated_shutdown_behavior = "stop"

  tags = {
    Name            = "${format("${var.name_tag}-%02d", count.index + 1)}"
    Description     = "${var.description_tag}"
    Group           = "${var.group_tag}"
  }
}
