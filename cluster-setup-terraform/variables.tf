variable "aws_region" {
type = string
default = "ap-south-1"
}


variable "vpc_cidr" {
type = string
default = "10.0.0.0/16"
}


variable "public_subnet_cidr" {
type = string
default = "10.0.1.0/24"
}


variable "controlplane_subnet_cidr" {
type = string
default = "10.0.2.0/24"
}


variable "worker_subnet_cidr" {
type = string
default = "10.0.3.0/24"
}


variable "availability_zones" {
type = list(string)
default = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

variable "key_name" {
type = string
description = "Existing EC2 key pair name to use for SSH access to instances"
}


variable "bastion_instance_type" {
type = string
default = "t3.micro"
}


variable "controlplane_instance_type" {
type = string
default = "t3.medium"
}


variable "worker_instance_type" {
type = string
default = "t3.medium"
}


variable "controlplane_count" {
type = number
default = 3
}


variable "worker_count" {
type = number
default = 3
}
variable "aws_region" {
description = "AWS region"
type = string
default = "ap-south-1"
}


variable "aws_access_key" {
description = "AWS access key"
type = string
sensitive = true
}


variable "aws_secret_key" {
description = "AWS secret key"
type = string
sensitive = true
}


variable "key_name" {
description = "EC2 key pair name"
type = string
}


variable "my_ip" {
description = "Your public IP for SSH (e.g. 203.0.113.25/32)"
type = string
}