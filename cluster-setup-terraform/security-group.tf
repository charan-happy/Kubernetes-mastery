resource "aws_security_group" "bastion_sg" {
name = "bastion-sg"
description = "Allow SSH from your IP"
vpc_id = aws_vpc.k8s_vpc.id


ingress {
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["115.99.215.112/32"] # Replace with your IP /32 in terraform.tfvars
}


egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
tags = { Name = "bastion-sg" }
}


resource "aws_security_group" "controlplane_sg" {
name = "controlplane-sg"
description = "K8s control plane security group"
vpc_id = aws_vpc.k8s_vpc.id
ingress {
from_port = 6443
to_port = 6443
protocol = "tcp"
security_groups = [aws_security_group.bastion_sg.id]
}


# etcd ports internal
ingress {
from_port = 2379
to_port = 2380
protocol = "tcp"
cidr_blocks = [var.vpc_cidr]
}


# kubelet / control-plane ports
ingress {
from_port = 10250
to_port = 10252
protocol = "tcp"
cidr_blocks = [var.vpc_cidr]
}


egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
tags = { Name = "controlplane-sg" }
}

resource "aws_security_group" "worker_sg" {
name = "worker-sg"
description = "K8s worker security group"
vpc_id = aws_vpc.k8s_vpc.id


ingress {
from_port = 10250
to_port = 10250
protocol = "tcp"
cidr_blocks = [var.vpc_cidr]
}


# NodePort range (restricted to VPC)
ingress {
from_port = 30000
to_port = 32767
protocol = "tcp"
cidr_blocks = [var.vpc_cidr]
}


egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
tags = { Name = "worker-sg" }
}

