
resource "aws_instance" "controlplane" {
depends_on = [aws_key_pair.k8s_key]
  count                  = var.controlplane_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.controlplane_instance_type
  subnet_id              = aws_subnet.controlplane.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.controlplane_sg.id]
  private_ip             = cidrhost(aws_subnet.controlplane.cidr_block, 10 + count.index)
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
  tags = {
    Name = "k8s-controlplane-${count.index + 1}"
  }
}

resource "aws_instance" "worker" {
depends_on = [aws_key_pair.k8s_key]
  count                  = var.worker_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  subnet_id              = aws_subnet.worker.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.worker_sg.id]
  private_ip             = cidrhost(aws_subnet.worker.cidr_block, 10 + count.index)
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}
