# Docker Orchestration Repository
## Purpose
This repository is responsible for provisioning a Docker Swarm. It depends on the Salt Configuration Repository for the salt state files that are placed on each instance.

## Branching Model
### Overview
This repository contains definitions that need to follow an organization's environment model with changes deployed to non-production environments and tested before being deployed to the production environment.  To account for this I am using a branch-based deployment model wherein a permanent branch is created to represent each of the runtime environments supported by an organization. Terraform workspaces are created to mirror this approach so that state will be maintained at a branch/environment level.  The workspace is then used within the Terraform templates to assign environment-specific names to security groups, instances, DNS entries, etc.

### Detail
1. Modifications are made to feature branches created from the development branch.
2. Feature branches are then merged into the development branch via pull-request.
3. The development branch will automatically create/update Docker instances running in the development environment.
4. Once the change has been tested in the development environment they can be merged into the production branch.
5. The production branch will automatically create/update Docker instances running in the production environment when updated.

## Pipeline
1. All Terraform files will be validated whenever any branch is updated.
2. A Terraform Plan is run and the plan persisted whenever the development or production branches change.
3. A Terraform Apply is run for the persisted plan whenever the development or production branches change.

## Terraform
## Inputs
| Variable | Description |
| -------- | ----------- |
| CI_API_V4_URL | This is a built-in Gitlab variable containing its REST API. It is used to save the provisioned Docker client certificates to the appropriate Gitlab groups. |
| CI_COMMIT_SHORT_SHA | This is the hash representing the current revision of the code being built/deployed. It is used as a version number for variables saved in Gitlab. |
| GITLAB_TOKEN | This is a personal access token used to authenticate to Gitlab's REST API. |
| ssh_username | The user that we should use for ssh connections. This is used to connect to Docker instances to mount the EFS drive and connect to Salt Master to update state. |
| ssh_private_key | The contents of a base64-encoded SSH private key to use for the connection. |

## Processing
1. Uses AWS data providers to retrieve VPC, subnet, and DNS zone identifiers for use in downstream resources.
2. Creates a Docker instance-specific security group to enable restricted inbound access to SSH, restricted access to various ports used by Docker Swarm, unrestricted access to ports 80 and 443, and unrestricted outbound access.
3. Creates one or more Docker instances from the CentOS Golden Image created by Packer.
4. Creates a Route53 health check for each instance and assigns it to common load-balanced Route53 records at the cluster, manager, and worker levels.
5. Creates a separate Route53 record for each unique instance name.
6. Creates certificates and key to enable secure certificate-based authentication to the Docker socket for deployment purposes.
7. Uses the "migrate_grain" module from the Salt Configuration repository to assign the grains pertaining to the Docker role on each instance.
8. Copies the previously created certificates to each Docker instance.
9. Applies the Salt state to all Docker instances to install various packages including, but not limited to: the AWS CLI, NFS, and Docker.
10. Provisions an EFS drive and mounts and mounts it to each Docker instance.
11. Initializes Docker Swarm.
12. Saves Docker certificate information to a Gitlab group to allow other Docker application deployments to leverage them.

## Outputs
| Variable | Description |
| -------- | ----------- |
| DOCKER_CA_CRT | Public certificate for the Certificate Authority used to sign both the server and client keys used to secure the Docker socket. |
| DOCKER_CLIENT_CRT | Public certificate used by clients to communicate to Docker Swarm over the Docker socket. |
| DOCKER_CLIENT_KEY | Private key used by clients to communcate to Docker Swarm over the Docker socket. |
