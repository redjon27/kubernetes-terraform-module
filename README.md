# kubernetes-terraform-module

# AWS EKS Platform – Terraform (dev / test / prod)

This repository provisions a production-style AWS EKS platform using Terraform.
It follows an enterprise-friendly structure with reusable modules and isolated
Terraform state per environment.

----------------------------------------------------------------

## Repository Structure

```text
├── bootstrap/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── modules/
│   └── eks-platform/
│       ├── vpc.tf
│       ├── eks.tf
│       ├── addons.tf
│       ├── locals.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── envs/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── backend.hcl
│   │   └── terraform.tfvars
│   ├── test/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── backend.hcl
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
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
```text
## Prerequisites

- Terraform >= 1.6
- AWS CLI v2
- AWS credentials (Access Keys or SSO)
- IAM permissions to manage EKS, VPC, IAM, EC2, S3, DynamoDB
```
----------------------------------------------------------------
```text
## Bootstrap Terraform State (S3 + DynamoDB)

The `bootstrap/backend` directory creates:
- An S3 bucket for Terraform state
- A DynamoDB table for state locking

cd bootstrap/backend
terraform init
terraform plan
terraform apply
```
----------------------------------------------------------------
```text
## Deploy an Environment

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
```text
## Access the EKS Cluster

Example for dev:

aws eks update-kubeconfig
--region eu-central-1
--name redi-eks-dev

kubectl get nodes
kubectl get pods -A

```
----------------------------------------------------------------
```text
## EKS Access Permissions (kubectl & AWS Console)

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
```text
## Environment Configuration

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

```text
## Architecture & Design Choices

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
```text
### Troubleshooting

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
```text
## Cluster Autoscaler (Flag-Based, Optional)

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
```text
## Destroy an Environment

cd envs/dev|test|prod
terraform destroy -var-file=terraform.tfvars
```
----------------------------------------------------------------
```text
## Notes

- Commit `.terraform.lock.hcl`
- Do not commit Terraform state files
- Use least-privilege IAM policies in production
- Keep core infrastructure and operational add-ons clearly separated
- Prefer least-privilege IAM policies in production
```