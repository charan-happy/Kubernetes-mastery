# Setup kubernetes cluster manually in AWS

| Stage                          | Goal                                                                     | AWS Services / Tools                             |
| ------------------------------ | ------------------------------------------------------------------------ | ------------------------------------------------ |
| **1. Networking foundation**   | Create isolated, secure VPC networking for the cluster.                  | VPC, Subnets, Route Tables, Internet/NAT Gateway |
| **2. Bastion host**            | Securely access private nodes without exposing them to the internet.     | EC2 (Bastion)                                    |
| **3. Cluster nodes**           | Provision control-plane and worker nodes with best practices (HA ready). | EC2 with autoscaling groups                      |
| **4. Security**                | IAM roles, Security Groups, TLS certs, restricted access.                | IAM, KMS (optional)                              |
| **5. Kubernetes installation** | Install Kubernetes manually with `kubeadm`.                              | kubeadm, containerd                              |
| **6. Addons**                  | CNI, CSI, Metrics, Logging, Monitoring.                                  | Calico, AWS EBS CSI, Metrics Server, Prometheus  |
| **7. Production operations**   | Upgrades, patching, backups, scaling, DR drills.                         | kubeadm, Velero, AWS Snapshots                   |
| **8. CI/CD & GitOps**          | Automate delivery and GitOps for production apps.                        | GitHub Actions, ArgoCD                           |



## Step 1 – AWS VPC & Networking

We’ll create a dedicated VPC with private and public subnets for a secure production-like cluster.

1. VPC Design

```
VPC: 10.0.0.0/16
│
├─ Public Subnet (10.0.1.0/24)
│  ├─ Bastion Host (SSH Jump Box)
│  └─ NAT Gateway (to allow private nodes outbound access)
│
└─ Private Subnets
   ├─ Control Plane Nodes (10.0.2.0/24)
   └─ Worker Nodes (10.0.3.0/24)

```

Public subnet: Only Bastion + NAT Gateway are here.

Private subnet: All Kubernetes nodes are private, no direct internet exposure.

1.2 Create VPC via AWS Console (manual)

Later we’ll automate with Terraform, but let’s first do it manually to understand.

Create VPC

Go to VPC → Create VPC.

Name: k8s-prod-vpc

IPv4 CIDR: 10.0.0.0/16

Enable DNS hostnames: Yes

Create Subnets

Public Subnet:

Name: k8s-public-subnet

CIDR: 10.0.1.0/24

Availability Zone: ap-south-1a (example)

Private Control Plane Subnet:

Name: k8s-controlplane-subnet

CIDR: 10.0.2.0/24

Private Worker Subnet:

Name: k8s-worker-subnet

CIDR: 10.0.3.0/24

Create Internet Gateway

Name: k8s-igw

Attach to k8s-prod-vpc.

Create NAT Gateway

In public subnet.

Allocate Elastic IP.

Name: k8s-nat-gateway.

Route Tables

Public Route Table

Name: k8s-public-rt

Route: 0.0.0.0/0 → Internet Gateway

Associate with public subnet.

Private Route Table

Name: k8s-private-rt

Route: 0.0.0.0/0 → NAT Gateway

Associate with control plane and worker subnets.

## 1.3 Security group
- Create 3 security group for layered access :
  
| SG Name             | Rules                                                                                                                          | Attached To         |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------- |
| **bastion-sg**      | Inbound: SSH (22) from **your IP**                                                                                             | Bastion EC2         |
| **controlplane-sg** | Inbound: 6443 (API server) from bastion + workers<br>etcd ports (2379-2380) internal only<br>10250, 10251, 10252 internal only | Control Plane nodes |
| **worker-sg**       | Inbound: 10250 (kubelet)<br>30000-32767 (NodePort) internal only                                                               | Worker nodes        |

Step 2 – Bastion Host

This acts as a secure jump box to access the private Kubernetes nodes.

Step 2 – Bastion Host

This acts as a secure jump box to access the private Kubernetes nodes.

Launch EC2:

AMI: Ubuntu 22.04

Type: t3.micro (cheap)

Subnet: Public subnet (k8s-public-subnet)

Assign Elastic IP.

Attach bastion-sg.

SSH from your laptop to Bastion:
ssh -i ~/.ssh/k8s-key.pem ubuntu@<Elastic-IP>

From Bastion → connect to private nodes via internal IPs only.

Step 3 – Kubernetes Cluster Nodes

We will launch:

3 Control Plane nodes (for HA)

3 Worker nodes

3.1 Control Plane nodes

AMI: Ubuntu 22.04 LTS

Type: t3.medium

Subnet: k8s-controlplane-subnet

Security Group: controlplane-sg

Storage: 30GB gp3

IAM Role: K8sControlPlaneRole (future for CSI and cloud provider integrations)

3.2 Worker nodes

Same as above, but:

Subnet: k8s-worker-subnet

Security Group: worker-sg

IAM Role: K8sWorkerRole

Step 4 – SSH Flow Check

Now the flow should be:

`Your Laptop → SSH → Bastion Host → SSH → Control Plane or Worker Node`
on Baston :
`# Example: SSH into control plane node
ssh -i ~/.ssh/k8s-key.pem ubuntu@10.0.2.10`

