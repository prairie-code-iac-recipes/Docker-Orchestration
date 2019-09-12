output "ami_id" {
  value       = "${data.aws_ami.default.id}"
  description = "AWS-assigned identifier for the AMI whose name was provided as input."
  sensitive   = false
}

output "app_zone_ids" {
  description = "AWS-assigned identifiers for the containerized application DNS host zones."
  value       = "${data.aws_route53_zone.app.*.id}"
  sensitive   = false
}

output "primary_zone_id" {
  description = "AWS-assigned identifier for the primary DNS host zone."
  value       = "${data.aws_route53_zone.primary.id}"
  sensitive   = false
}

output "private_subnet_cidrs" {
  description = "The subnet cidrs assigned to the private subnets in the Shared Infrastructure VPC."
  value       = "${data.aws_subnet.private.*.cidr_block}"
  sensitive   = false
}

output "private_subnet_ids" {
  description = "The AWS-assigned unique identifiers assigned to the private subnets in the Shared Infrastructure VPC."
  value       = "${data.aws_subnet.private.*.id}"
  sensitive   = false
}

output "public_subnet_cidrs" {
  description = "The subnet cidrs assigned to the public subnets in the Shared Infrastructure VPC."
  value       = "${data.aws_subnet.public.*.cidr_block}"
  sensitive   = false
}

output "public_subnet_ids" {
  description = "The AWS-assigned unique identifiers assigned to the public subnets in the Shared Infrastructure VPC."
  value       = "${data.aws_subnet.public.*.id}"
  sensitive   = false
}

output "vpc_cidr_block" {
  description = "This is the CIDR block associated with the Shared Infrastructure VPC."
  value       = "${data.aws_vpc.default.cidr_block}"
  sensitive   = false
}

output "vpc_id" {
  description = "This is the CIDR block associated with the Shared Infrastructure VPC."
  value       = "${data.aws_vpc.default.id}"
  sensitive   = false
}
