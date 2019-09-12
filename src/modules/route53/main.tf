locals {
  cluster_fqdn = "${var.name_tag}.${var.primary_domain}"
  manager_fqdn = "${var.name_tag}-manager.${var.primary_domain}"
  worker_fqdn = "${var.name_tag}-worker.${var.primary_domain}"
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
# Common Name for All Servers
###############################################################################
resource "aws_route53_health_check" "default" {
  count = "${length(var.ipv4_addresses)}"

  ip_address        = "${element(var.ipv4_addresses, count.index)}"
  port              = 22
  type              = "TCP"
  failure_threshold = "5"
  request_interval  = "30"

  depends_on = [
    null_resource.waited_on
  ]
}

resource "aws_route53_record" "default" {
  count           = "${length(var.ipv4_addresses)}"

  zone_id         = "${var.primary_zone_id}"
  name            = "${local.cluster_fqdn}"
  type            = "A"
  ttl             = "30"
  health_check_id = "${element(aws_route53_health_check.default.*.id, count.index)}"

  weighted_routing_policy {
    weight = 10
  }
  set_identifier  = "${format("${var.name_tag}.${var.primary_domain}.%02d", count.index+1)}"

  records = [
    "${element(var.ipv4_addresses, count.index)}"
  ]
}

###############################################################################
# Unique Server Instance Names
###############################################################################
resource "aws_route53_record" "unique_instance_dns_names" {
  count   = "${length(var.ipv4_addresses)}"

  zone_id = "${var.primary_zone_id}"
  name    = "${format("${var.name_tag}-%02d", count.index + 1)}.${var.primary_domain}"
  type    = "A"
  ttl     = "30"

  records = [
    "${element(var.ipv4_addresses, count.index)}"
  ]

  depends_on = [
    null_resource.waited_on
  ]
}

###############################################################################
# Create DNS Entries for Swarm Manager Nodes
###############################################################################
resource "aws_route53_record" "manager_dns_name" {
  count = "${var.manager_count}"

  zone_id = "${var.primary_zone_id}"
  name    = "${local.manager_fqdn}"
  type    = "A"
  ttl     = "30"
  health_check_id = "${element(aws_route53_health_check.default.*.id, count.index)}"

  weighted_routing_policy {
    weight = 10
  }
  set_identifier  = "${format("${var.name_tag}-manager.${var.primary_domain}.%02d", count.index+1)}"

  records = [
    "${element(var.ipv4_addresses, count.index)}"
  ]
}

###############################################################################
# Create DNS Entries for Swarm Worker Nodes
###############################################################################
resource "aws_route53_record" "worker_dns_name" {
  count = "${length(var.ipv4_addresses) > var.manager_count ? length(var.ipv4_addresses) - var.manager_count : 0}"

  zone_id         = "${var.primary_zone_id}"
  name            = "${local.worker_fqdn}"
  type            = "A"
  ttl             = "30"
  health_check_id = "${element(aws_route53_health_check.default.*.id, count.index + var.manager_count)}"

  weighted_routing_policy {
    weight = 10
  }
  set_identifier  = "${format("${var.name_tag}-worker.${var.primary_domain}.%02d", count.index+1)}"

  records = [
     "${element(var.ipv4_addresses, count.index + var.manager_count)}"
  ]
}

###############################################################################
# Create DNS Entries for Application Domains
###############################################################################
resource "aws_route53_record" "app" {
  count = "${length(var.app_domains) * length(var.ipv4_addresses)}"

  zone_id = "${element(var.app_zone_ids, floor(count.index / length(var.ipv4_addresses)))}"
  name    = "*.${element(var.app_domains, floor(count.index / length(var.ipv4_addresses)))}"
  type    = "A"
  ttl     = "30"
  health_check_id = "${element(aws_route53_health_check.default.*.id, count.index % length(var.ipv4_addresses))}"

  weighted_routing_policy {
    weight = 10
  }
  set_identifier  = "${format("*.${element(var.app_domains, floor(count.index / length(var.ipv4_addresses)))}.%02d", count.index % length(var.ipv4_addresses) + 1)}"

  records = [
    "${element(var.ipv4_addresses, count.index % length(var.ipv4_addresses))}"
  ]
}
