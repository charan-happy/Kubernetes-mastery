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


```
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl unzip
```
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install
```

```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list && sudo apt-get update && sudo apt-get install -y terraform
```

`terraform --version`
`aws --version`



provider "aws" {
  region = var.aws_region
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}