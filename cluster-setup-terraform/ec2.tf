

# Key Pair
resource "aws_key_pair" "k8s_key" {
  key_name   = var.key_name
  public_key = file("~/.ssh/${var.key_name}.pub")
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = var.bastion_instance_type
  subnet_id     = aws_subnet.public.id
  key_name      = aws_key_pair.k8s_key.key_name
  security_groups = [aws_security_group.bastion_sg.id]
  tags = {
    Name = "k8s-bastion"
  }
}

# Control Plane Nodes
resource "aws_instance" "control_plane" {
  count         = var.control_plane_count
  ami           = var.ami_id
  instance_type = var.control_plane_instance_type
  subnet_id     = aws_subnet.private_control.id
  key_name      = aws_key_pair.k8s_key.key_name
  security_groups = [aws_security_group.controlplane_sg.id]
  tags = {
    Name = "k8s-control-plane-${count.index + 1}"
  }
}

# Worker Nodes
resource "aws_instance" "worker" {
  count         = var.worker_count
  ami           = var.ami_id
  instance_type = var.worker_instance_type
  subnet_id     = aws_subnet.private_worker.id
  key_name      = aws_key_pair.k8s_key.key_name
  security_groups = [aws_security_group.worker_sg.id]
  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}

# Outputs
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "control_plane_private_ips" {
  value = [for instance in aws_instance.control_plane : instance.private_ip]
}

output "worker_private_ips" {
  value = [for instance in aws_instance.worker : instance.private_ip]
}
