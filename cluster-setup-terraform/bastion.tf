resource "aws_instance" "bastion" {
ami = data.aws_ami.ubuntu.id
instance_type = var.bastion_instance_type
subnet_id = aws_subnet.public.id
key_name = var.key_name
vpc_security_group_ids = [aws_security_group.bastion_sg.id]
associate_public_ip_address = true
tags = { Name = "k8s-bastion" }
}




