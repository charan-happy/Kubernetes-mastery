// === File: ec2.tf ===

# ---------------------------
# EC2 Key Pair (expects a public key file at ~/.ssh/<key_name>.pub)
# ---------------------------
resource "aws_key_pair" "k8s_key" {
  key_name   = var.key_name
  public_key = file("~/.ssh/${var.key_name}")
}

# ---------------------------
# Bastion Host (public subnet)
# ---------------------------


# ---------------------------
# Control Plane Nodes (private controlplane subnet)
# ---------------------------
resource "aws_instance" "control_plane" {
  count                  = var.controlplane_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.controlplane_instance_type
  subnet_id              = aws_subnet.controlplane.id
  key_name               = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids = [aws_security_group.controlplane_sg.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "k8s-control-plane-${count.index + 1}"
  }
}

# ---------------------------
# Worker Nodes (private worker subnet)
# ---------------------------

# ---------------------------
# Outputs
# ---------------------------
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "control_plane_private_ips" {
  description = "Private IPs of control plane instances"
  value       = [for i in aws_instance.control_plane : i.private_ip]
}

output "worker_private_ips" {
  description = "Private IPs of worker instances"
  value       = [for i in aws_instance.worker : i.private_ip]
}
