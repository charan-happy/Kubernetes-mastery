resource "aws_vpc" "k8s_vpc" {
cidr_block = var.vpc_cidr
enable_dns_hostnames = true
enable_dns_support = true
tags = {
Name = "k8s-prod-vpc"
}
}


resource "aws_subnet" "public" {
vpc_id = aws_vpc.k8s_vpc.id
cidr_block = var.public_subnet_cidr
availability_zone = var.availability_zones[0]
map_public_ip_on_launch = true
tags = { Name = "k8s-public-subnet" }
}


resource "aws_subnet" "controlplane" {
vpc_id = aws_vpc.k8s_vpc.id
cidr_block = var.controlplane_subnet_cidr
availability_zone = var.availability_zones[0]
map_public_ip_on_launch = false
tags = { Name = "k8s-controlplane-subnet" }
}

resource "aws_subnet" "worker" {
vpc_id = aws_vpc.k8s_vpc.id
cidr_block = var.worker_subnet_cidr
availability_zone = var.availability_zones[1]
map_public_ip_on_launch = false
tags = { Name = "k8s-worker-subnet" }
}


resource "aws_internet_gateway" "igw" {
vpc_id = aws_vpc.k8s_vpc.id
tags = { Name = "k8s-igw" }
}


resource "aws_eip" "nat" {
vpc = true
depends_on = [aws_internet_gateway.igw]
}


resource "aws_nat_gateway" "natgw" {
allocation_id = aws_eip.nat.id
subnet_id = aws_subnet.public.id
tags = { Name = "k8s-nat-gateway" }
}

resource "aws_route_table" "public_rt" {
vpc_id = aws_vpc.k8s_vpc.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.igw.id
}
tags = { Name = "k8s-public-rt" }
}


resource "aws_route_table_association" "public_assoc" {
subnet_id = aws_subnet.public.id
route_table_id = aws_route_table.public_rt.id
}


resource "aws_route_table" "private_rt" {
vpc_id = aws_vpc.k8s_vpc.id
route {
cidr_block = "0.0.0.0/0"
nat_gateway_id = aws_nat_gateway.natgw.id
}
tags = { Name = "k8s-private-rt" }
}


resource "aws_route_table_association" "controlplane_assoc" {
subnet_id = aws_subnet.controlplane.id
route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "worker_assoc" {
subnet_id = aws_subnet.worker.id
route_table_id = aws_route_table.private_rt.id
}