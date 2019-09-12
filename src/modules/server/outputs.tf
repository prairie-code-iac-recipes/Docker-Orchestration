output "availability_zones" {
  description = "The availability zones assoiated with the provisioned instances."
  value       = "${aws_instance.default.*.availability_zone}"
  sensitive   = false
}

output "instance_ids" {
  description = "The AWS-assigned identifiers associated with the provisioned instances."
  value       = "${aws_instance.default.*.id}"
  sensitive   = false
}

output "public_dns" {
  description = "AWS-assigned external-facing fully-qualified domain name pointing to all servers."
  value       = "${aws_instance.default.*.public_dns}"
  sensitive   = false
}

output "public_ips" {
  description = "Public IP addresses associated with the provisioned instances."
  value       = "${aws_instance.default.*.public_ip}"
  sensitive   = false
}

output "private_dns" {
  description = "AWS-assigned internal-facing fully-qualified domain name pointing to all servers."
  value       = "${aws_instance.default.*.private_dns}"
  sensitive   = false
}

output "private_ips" {
  description = "Private IP addresses associated with the provisioned instances."
  value       = "${aws_instance.default.*.private_ip}"
  sensitive   = false
}

output "max_hostnum_offset" {
  description = "The largest offset used to assign IP addresses to provisioned instances. This offset may have been used to assign IP addresses to multiple instances if multiple subnets were specified."
  value       = "${lookup(data.external.host_offset.result, "max")}"
  sensitive   = false
}

output "wait_on" {
  description = "This output can be passed in another module's waited_on input to force an inter-module dependency."
  value       = "Docker Servers Provisioned"
  depends_on  = [
    null_resource.accept_key
  ]
}
