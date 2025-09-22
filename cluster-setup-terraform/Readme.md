 === File: README.md ===
# Terraform: k8s-prod-vpc


This Terraform config provisions a production-like VPC for a Kubernetes cluster on AWS:
- VPC with public & private subnets (control-plane & worker)
- Internet Gateway and NAT Gateway
- Route tables and associations
- Security Groups (bastion, controlplane, worker)
- Bastion EC2 instance
- EC2 instances for control-plane and worker nodes (counts configurable)


**Usage**:
1. Copy files to a directory.
2. `terraform init`
3. `terraform plan -var-file="terraform.tfvars"`
4. `terraform apply -var-file="terraform.tfvars"`

---
