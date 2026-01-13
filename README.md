# kubernetes-terraform-module

# AWS EKS Platform – Terraform (dev / test / prod)

This repository provisions a production-style AWS EKS platform using Terraform.
It follows an enterprise-friendly structure with reusable modules and isolated
Terraform state per environment.

### Table of Contents

- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Bootstrap Terraform State](#bootstrap-terraform-state-s3--dynamodb)
- [Deploy an Environment](#deploy-an-environment)
- [Access the EKS Cluster](#access-the-eks-cluster)
- [EKS Access Permissions](#eks-access-permissions-kubectl--aws-console)
- [Environment Configuration](#environment-configuration)
- [Architecture & Design Choices](#architecture--design-choices)
- [Production: Private-Only Cluster Access](#production-private-only-cluster-access-nat-disabled)
- [Cluster Autoscaler](#cluster-autoscaler-flag-based-optional)
- [Troubleshooting](#troubleshooting)
- [Destroy an Environment](#destroy-an-environment)
- [Notes](#notes)

----------------------------------------------------------------
### Repository Structure
```text
├── bootstrap/
│   └── backend/
│       ├── main.tf
│       ├── providers.tf
│       ├── versions.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
│
├── modules/
│   └── eks-platform/
│       ├── vpc.tf
│       ├── eks.tf
│       ├── vpc_endpoints.tf
│       ├── addons.tf
│       ├── locals.tf
│       ├── variables.tf
│       ├── versions.tf
│       └── outputs.tf
│
├── envs/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── version.tf
│   │   ├── backend.hcl
│   │   └── terraform.tfvars
│   │   
│   ├── test/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── backend.hcl
│   │   ├── outputs.tf
│   │   ├── version.tf
│   │   └── terraform.tfvars
│   │   
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── version.tf
│       ├── backend.hcl
│       └── terraform.tfvars
│
└── tests/
    └── autoscaler/
        └── scripts/
            ├── cluster-autoscaler.sh
            ├── cluster-autoscaler-uninstall.sh
            └── stress.yaml

Each environment has its own Terraform state stored in S3 and locked via DynamoDB.
```
----------------------------------------------------------------
### Prerequisites
```text
- Terraform >= 1.6
- AWS CLI v2
- AWS credentials (Access Keys or SSO)
- IAM permissions to manage EKS, VPC, IAM, EC2, S3, DynamoDB
```
----------------------------------------------------------------
### Bootstrap Terraform State (S3 + DynamoDB)
```text
The `bootstrap/backend` directory creates:
- An S3 bucket for Terraform state
- A DynamoDB table for state locking

cd bootstrap/backend
terraform init
terraform plan
terraform apply
```
----------------------------------------------------------------
### Deploy an Environment
```text
### Dev
cd envs/dev
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply

### Test
cd envs/test
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply

### Prod
cd envs/prod
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply

```
----------------------------------------------------------------
### Access the EKS Cluster
```text
Example for dev:

aws eks update-kubeconfig
--region eu-central-1
--name redi-eks-dev

kubectl get nodes
kubectl get pods -A

```
----------------------------------------------------------------
### EKS Access Permissions (kubectl & AWS Console)
```text
EKS requires explicit IAM access entries.

If you see:
> "Your current IAM principal doesn't have access to Kubernetes objects"

Create an access entry for your IAM principal:

PRINCIPAL_ARN=$(aws sts get-caller-identity --query Arn --output text)

aws eks create-access-entry
--cluster-name redi-eks-dev
--principal-arn "$PRINCIPAL_ARN"
--region eu-central-1

aws eks associate-access-policy
--cluster-name redi-eks-dev
--principal-arn "$PRINCIPAL_ARN"
--policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy
--access-scope type=cluster
--region eu-central-1

```
----------------------------------------------------------------
### Environment Configuration
```text
Each environment controls:
- Kubernetes version
- VPC CIDR
- Public / private cluster endpoint access
- NAT Gateway usage
- Node group scaling and instance types

Example `terraform.tfvars`:

aws_region = "eu-central-1"
name = "redi-eks-dev"
k8s_version = "1.34"

azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
vpc_cidr = "10.10.0.0/16"

enable_nat_gateway = true

cluster_endpoint_public_access = true
cluster_endpoint_private_access = true

node_group = {
desired_size = 1
min_size = 1
max_size = 2
instance_types = ["t3.large"]
capacity_type = "ON_DEMAND"
disk_size = 20
}
```
----------------------------------------------------------------
### Architecture & Design Choices
```text
- **Multi-environment isolation** using separate Terraform state per env
- **Reusable Terraform module** (`modules/eks-platform`)
- **EKS Managed Node Groups** for simplicity and stability
- **Private subnets for nodes** with NAT Gateway for outbound access
- **IRSA enabled** for future AWS integrations
- **EKS Add-ons managed declaratively**
  - vpc-cni
  - coredns
  - kube-proxy
- **EKS Access Entries** instead of legacy `aws-auth` ConfigMap
```
----------------------------------------------------------------
### Troubleshooting
```text
### Nodes fail to join the cluster
- Ensure NAT Gateway is enabled when nodes are in private subnets
- Verify endpoint access settings

### CoreDNS stuck in DEGRADED
- Usually caused by nodes not being Ready
- Fix node networking first

### kubectl authentication errors
- Re-run `aws eks update-kubeconfig`
- Ensure your IAM principal has an EKS access entry
```
----------------------------------------------------------------
### Cluster Autoscaler (Flag-Based, Optional)
```text
Cluster Autoscaler is optional and intentionally not part of the core EKS module.

Design principles:
- Core infrastructure remains clean and destroy-safe
- Autoscaler can be enabled or disabled per environment
- IAM (IRSA) is managed by Terraform
- Kubernetes resources are managed via scripts and Helm

IAM (IRSA) is managed by Terraform
- Kubernetes resources are managed via scripts + Helm
- Enable Autoscaler (Dev Example)

Enable flag in Terraform:
- enable_cluster_autoscaler = true
- cd envs/dev
- terraform apply -var-file=terraform.tfvars


Install autoscaler:
- ./tests/autoscaler/scripts/cluster-autoscaler.sh devdev/test/prod

Verify:
- kubectl -n kube-system get pods | grep autoscaler

Disable Autoscaler
- Uninstall from cluster:
- ./tests/autoscaler/scripts/cluster-autoscaler-uninstall.sh dev/test/prod

Disable IAM in Terraform:
- enable_cluster_autoscaler = false
- cd envs/dev
- terraform apply -var-file=terraform.tfvars

Note: 
Autoscaler scale-up may leave the node group with a higher desired capacity.
In that case, reset ASG desired capacity back to baseline (e.g. 1).

Cluster Autoscaler Stress Test (Validation)
- A simple stress workload is provided to validate autoscaler behavior.
- kubectl apply -f tests/autoscaler/scripts/stress.yaml
- kubectl get pods
- kubectl get nodes

Expected behavior:
- Pods become Pending
- Autoscaler increases node group size
- New node joins the cluster

Cleanup:
- kubectl delete -f tests/autoscaler/scripts/stress.yaml

Troubleshooting:
- Nodes fail to join the cluster
- Ensure NAT Gateway is enabled for private subnets
- Verify cluster endpoint access
- CoreDNS stuck in DEGRADED
- Usually caused by nodes not being Ready
- Fix node networking first
- kubectl authentication errors
- Re-run aws eks update-kubeconfig
- Ensure your IAM principal has an EKS access entry
- Node does not scale down after autoscaler removal
- Autoscaler modifies ASG desired capacity
- Manually reset ASG desired capacity or re-apply Terraform baseline
```
----------------------------------------------------------------
### Production: Private-Only Cluster Access (NAT Disabled)
```text
The production environment is designed as a **private-only EKS cluster**.

Production settings:
- `cluster_endpoint_public_access = false`
- `cluster_endpoint_private_access = true`
- `enable_nat_gateway = false`

This design ensures:
- No public exposure of the Kubernetes API
- No direct internet egress from worker nodes
- All traffic remains within the AWS private network

### How nodes join the cluster without NAT
When `enable_nat_gateway = false`, worker nodes run in private subnets and have **no direct internet access**.

To allow nodes to:
- Pull container images
- Authenticate with AWS APIs
- Join the Kubernetes cluster successfully

The platform **automatically provisions VPC Endpoints (PrivateLink)** for:
- Amazon ECR (api, dkr)
- Amazon STS
- Amazon EC2
- Amazon S3 (Gateway Endpoint)
- Amazon CloudWatch Logs
- AWS Systems Manager (SSM)

These endpoints are created **only when NAT is disabled**, ensuring:
- Dev/Test environments remain simple
- Production remains secure and private

### Important: kubectl access in production
Because the EKS API endpoint is private-only:

Running `kubectl` from a local machine **will not work** unless you are connected to the VPC.

Expected error when accessing from outside:
dial tcp <private-ip>:443: i/o timeout


### Supported access methods for production
To manage the production cluster, use one of the following:

1. **AWS Client VPN**
   - Connect to the VPC
   - Run `kubectl` normally after VPN connection

2. **SSM Session Manager (recommended)**
   - Use an EC2 admin instance inside the VPC
   - No public IP, no inbound ports
   - Fully audited and secure

3. **Bastion Host**
   - SSH into a host inside the VPC
   - Run `kubectl` from there

### Temporary public access (not recommended for long-term)
For short administrative tasks, the EKS API can be temporarily exposed:

- Enable public access
- Restrict access to a specific IP using CIDR (`/32`)
- Revert back to private-only after completion

This approach should be used **only when absolutely necessary**.

### Troubleshooting: Nodes fail to join / CoreDNS DEGRADED
If you encounter:
- `NodeCreationFailure`
- `CoreDNS` stuck in `DEGRADED`

Check the following:
- NAT is enabled **or**
- Required VPC Endpoints exist when NAT is disabled

In private-only production clusters, missing VPC endpoints will prevent nodes from joining the cluster.
```
----------------------------------------------------------------
### Destroy an Environment
```text
cd envs/dev|test|prod
terraform destroy -var-file=terraform.tfvars
```
----------------------------------------------------------------
### Notes
```text
- Commit `.terraform.lock.hcl`
- Do not commit Terraform state files
- Use least-privilege IAM policies in production
- Keep core infrastructure and operational add-ons clearly separated
- Prefer least-privilege IAM policies in production
```