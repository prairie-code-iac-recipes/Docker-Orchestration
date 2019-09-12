output "cluster_fqdn" {
  description = "Fully-qualified domain name pointing to all servers."
  value       = "${local.cluster_fqdn}"
  sensitive   = false
}

output "member_fqdns" {
  description = "Fully-qualified domain name pointing to each individual server."
  value       = "${aws_route53_record.unique_instance_dns_names.*.fqdn}"
  sensitive   = false
}

output "manager_fqdn" {
  description = "Fully-qualified domain name pointing to all manager servers."
  value       = "${local.manager_fqdn}"
  sensitive   = false
}

output "worker_fqdn" {
  description = "Fully-qualified domain name pointing to all worker servers."
  value       = "${local.worker_fqdn}"
  sensitive   = false
}

output "wait_on" {
  description = "This output can be passed in another module's waited_on input to force an inter-module dependency."
  value       = "Route 53 Records Created"
  depends_on  = [
    aws_route53_record.default,
    aws_route53_record.unique_instance_dns_names,
    aws_route53_record.manager_dns_name,
    aws_route53_record.worker_dns_name,
    aws_route53_record.app
  ]
}
