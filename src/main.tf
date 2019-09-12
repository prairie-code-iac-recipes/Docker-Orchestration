###############################################################################
# Setup
###############################################################################
provider "aws" {
  version = "~> 2.23"
  region  = "us-east-1"
}

provider "external" {
  version = "~> 1.2"
}

provider "gitlab" {
  version = "~> 2.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "tls" {
  version = "~> 2.1"
}

terraform {
  backend "s3" {
    bucket         = "com.iac-example"
    key            = "docker-orchestration"
    region         = "us-east-1"
    dynamodb_table = "terraform-statelock"
  }
}

###############################################################################
# Local Variables
###############################################################################
locals {
  ami_name                  = "linux-centos-7-1810-aee8db4c"
  app_domains               = [
    "swarm-apps.com"
  ]
  availability_zones        = [
    "us-east-1a",
    "us-east-1b"
  ]
  description_tag           = "Managed By Terraform"
  gitlab_docker_ca_crt      = "TF_VAR_DOCKER_CA_CRT"
  gitlab_docker_client_crt  = "TF_VAR_DOCKER_CLIENT_CRT"
  gitlab_docker_client_key  = "TF_VAR_DOCKER_CLIENT_KEY"
  gitlab_group_id           = 5532256
  gitlab_group_name         = "prairie-code-iac-recipes"
  group_tag                 = "Network Infrastructure"
  primary_domain            = "iac-example.com"
  docker_instance_count     = 6
  docker_instance_type      = "t2.micro"
  docker_instance_name      = "docker"
  docker_manager_count      = 3
  role                      = "docker"
  saltmaster_external       = "salt-${terraform.workspace}.${local.primary_domain}"
  saltmaster_internal       = "salt-${terraform.workspace}-internal.${local.primary_domain}"
  ssh_private_key           = "${base64decode(var.ssh_private_key)}"
  starting_hostnum          = 10
  vpc_cidr_block            = "172.32.0.0/16"
  whitelist_cidrs           = [
    "216.161.127.151/32",
    "${local.vpc_cidr_block}"
  ]
}

###############################################################################
# Data Retrieval
###############################################################################
module "data" {
  source  = "./modules/data"

  ami_name           = "${local.ami_name}"
  app_domains        = "${local.app_domains}"
  availability_zones = "${local.availability_zones}"
  primary_domain     = "${local.primary_domain}"
  vpc_cidr_block     = "${local.vpc_cidr_block}"
}

###############################################################################
# Docker Instances
###############################################################################
module "server" {
  source  = "./modules/server"

  ami                         = "${module.data.ami_id}"
  associate_public_ip_address = true
  availability_zones          = "${local.availability_zones}"
  description_tag             = "${local.description_tag}"
  group_tag                   = "${local.group_tag}"
  instance_count              = "${local.docker_instance_count}"
  instance_type               = "${local.docker_instance_type}"
  name_tag                    = "${local.docker_instance_name}-${terraform.workspace}"
  role                        = "${local.role}"
  saltmaster_external         = "${local.saltmaster_external}"
  saltmaster_internal         = "${local.saltmaster_internal}"
  ssh_username                = "${var.ssh_username}"
  ssh_private_key             = "${local.ssh_private_key}"
  starting_hostnum            = "${local.starting_hostnum}"
  subnet_ids                  = "${module.data.public_subnet_ids}"
  subnet_cidrs                = "${module.data.public_subnet_cidrs}"
  vpc_id                      = "${module.data.vpc_id}"
  whitelist_cidrs             = "${local.whitelist_cidrs}"
}

###############################################################################
# Setup DNS Records
###############################################################################
module "route53" {
  source = "./modules/route53"

  app_domains     = "${local.app_domains}"
  app_zone_ids    = "${module.data.app_zone_ids}"
  name_tag        = "${local.docker_instance_name}-${terraform.workspace}"
  ipv4_addresses  = "${module.server.public_ips}"
  manager_count   = "${local.docker_manager_count}"
  primary_domain  = "${local.primary_domain}"
  primary_zone_id = "${module.data.primary_zone_id}"
}

###############################################################################
# Create Certificates to Secure Docker Socket
###############################################################################
module "certificates" {
  source = "./modules/certificates"

  certificate_cn = "${local.docker_instance_name}-${terraform.workspace}.${local.primary_domain}"
  country             = "US"
  dns_names = "${concat(list(module.route53.cluster_fqdn, module.route53.manager_fqdn, module.route53.worker_fqdn), module.route53.member_fqdns, module.server.private_dns, module.server.public_dns)}"
  ip_addresses   = "${concat(module.server.public_ips, module.server.private_ips)}"
  locality            = "Norwalk"
  organization        = "Salte LLC"
  province            = "IA"
}

module "install" {
  source = "./modules/install"

  ca_crt              = "${module.certificates.ca_crt}"
  role                = "${local.role}"
  saltmaster_external = "${local.saltmaster_external}"
  saltmaster_internal = "${local.saltmaster_internal}"
  server_crt          = "${module.certificates.server_crt}"
  server_key          = "${module.certificates.server_key}"
  ssh_private_key     = "${local.ssh_private_key}"
  ssh_username        = "${var.ssh_username}"
  ipv4_addresses      = "${module.server.public_ips}"
}

###############################################################################
# Shared File System for Swarm
###############################################################################
module "efs" {
  source = "./modules/efs"

  description_tag = "${local.description_tag}"
  group_tag       = "${local.group_tag}"
  ipv4_addresses  = "${module.server.public_ips}"
  name_tag        = "${local.docker_instance_name}-${terraform.workspace}"
  ssh_private_key = "${local.ssh_private_key}"
  ssh_username    = "${var.ssh_username}"
  subnet_ids      = "${module.data.private_subnet_ids}"
  vpc_cidr_block  = "${module.data.vpc_cidr_block}"
  vpc_id          = "${module.data.vpc_id}"

  wait_on = [
    "${module.install.wait_on}"
  ]
}

###############################################################################
# Setup Swarm
###############################################################################
module "swarm" {
  source = "./modules/swarm"

  manager_count   = "${local.docker_manager_count}"
  private_ips     = "${module.server.private_ips}"
  public_ips      = "${module.server.public_ips}"
  ssh_private_key = "${local.ssh_private_key}"
  ssh_username    = "${var.ssh_username}"

  wait_on = [
    "${module.install.wait_on}",
  ]
}

###############################################################################
# Save Docker Client Certificates and Key to Gitlab Variables
###############################################################################
resource "null_resource" "docker_ca_cert_versioned" {
  triggers = {
    value_change = "${md5(module.certificates.ca_crt)}"
  }

  provisioner "local-exec" {
    command = "./scripts/save-versioned-variable.sh"

    environment = {
      GROUP_ID         = "${local.gitlab_group_id}"
      KEY              = "${local.gitlab_docker_ca_crt}"
      VALUE            = "${base64encode(module.certificates.ca_crt)}"
      VERSION          = "${var.CI_COMMIT_SHORT_SHA}"
      GITLAB_URL       = "${var.CI_API_V4_URL}"
      GITLAB_TOKEN     = "${var.GITLAB_TOKEN}"
    }
  }
}

resource "null_resource" "docker_client_cert_versioned" {
  triggers = {
    key_change = "${md5(module.certificates.client_crt)}"
  }

  provisioner "local-exec" {
    command = "./scripts/save-versioned-variable.sh"

    environment = {
      GROUP_ID         = "${local.gitlab_group_id}"
      KEY              = "${local.gitlab_docker_client_crt}"
      VALUE            = "${base64encode(module.certificates.client_crt)}"
      VERSION          = "${var.CI_COMMIT_SHORT_SHA}"
      GITLAB_URL       = "${var.CI_API_V4_URL}"
      GITLAB_TOKEN     = "${var.GITLAB_TOKEN}"
    }
  }
}

resource "null_resource" "docker_client_key_versioned" {
  triggers = {
    key_change = "${md5(module.certificates.client_crt)}"
  }

  provisioner "local-exec" {
    command = "./scripts/save-versioned-variable.sh"

    environment = {
      GROUP_ID         = "${local.gitlab_group_id}"
      KEY              = "${local.gitlab_docker_client_key}"
      VALUE            = "${base64encode(module.certificates.client_key)}"
      VERSION          = "${var.CI_COMMIT_SHORT_SHA}"
      GITLAB_URL       = "${var.CI_API_V4_URL}"
      GITLAB_TOKEN     = "${var.GITLAB_TOKEN}"
    }
  }
}

resource "gitlab_group_variable" "docker_ca_cert" {
  group                          = "${local.gitlab_group_name}"
  key                            = "${local.gitlab_docker_ca_crt}"
  value                          = "${base64encode(module.certificates.ca_crt)}"
  protected                      = false

  depends_on = [
    null_resource.docker_ca_cert_versioned,
    null_resource.docker_client_cert_versioned,
    null_resource.docker_client_key_versioned
  ]
}

resource "gitlab_group_variable" "docker_client_cert" {
  group                          = "${local.gitlab_group_name}"
  key                            = "${local.gitlab_docker_client_crt}"
  value                          = "${base64encode(module.certificates.client_crt)}"
  protected                      = false

  depends_on = [
    null_resource.docker_ca_cert_versioned,
    null_resource.docker_client_cert_versioned,
    null_resource.docker_client_key_versioned
  ]
}

resource "gitlab_group_variable" "docker_client_key" {
  group                          = "${local.gitlab_group_name}"
  key                            = "${local.gitlab_docker_client_key}"
  value                          = "${base64encode(module.certificates.client_key)}"
  protected                      = false

  depends_on = [
    null_resource.docker_ca_cert_versioned,
    null_resource.docker_client_cert_versioned,
    null_resource.docker_client_key_versioned
  ]
}
