data "aws_ami" "default" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self"]
}

data "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr_block}"
}

data "aws_subnet" "private" {
  count = "${length(var.availability_zones)}"

  availability_zone = "${var.availability_zones[count.index]}"
  filter {
    name   = "tag:Scope"
    values = ["private"]       # insert value here
  }
}

data "aws_subnet" "public" {
  count = "${length(var.availability_zones)}"

  availability_zone = "${var.availability_zones[count.index]}"
  filter {
    name   = "tag:Scope"
    values = ["private"]       # insert value here
  }
}

data "aws_route53_zone" "primary" {
  name = "${var.primary_domain}."
}

data "aws_route53_zone" "app" {
  count = "${length(var.app_domains)}"

  name = "${var.app_domains[count.index]}."
}
