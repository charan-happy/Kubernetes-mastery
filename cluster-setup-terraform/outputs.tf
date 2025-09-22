output "vpc_id" {
value = aws_vpc.k8s_vpc.id
}


output "public_subnet_id" {
value = aws_subnet.public.id
}


output "controlplane_subnet_id" {
value = aws_subnet.controlplane.id
}


output "worker_subnet_id" {
value = aws_subnet.worker.id
}


output "bastion_public_ip" {
value = aws_instance.bastion.public_ip
}


output "controlplane_private_ips" {
value = [for i in aws_instance.controlplane : i.private_ip]
}


output "worker_private_ips" {
value = [for i in aws_instance.worker : i.private_ip]
}

output "iam_user_name" {
description = "IAM user name for Terraform Kubernetes management"
value = aws_iam_user.k8s_terraform_user.name
}


output "iam_access_key_id" {
description = "Access key ID for new IAM user"
value = aws_iam_access_key.k8s_access_key.id
sensitive = true
}


output "iam_secret_access_key" {
description = "Secret access key for new IAM user"
value = aws_iam_access_key.k8s_access_key.secret
sensitive = true
}