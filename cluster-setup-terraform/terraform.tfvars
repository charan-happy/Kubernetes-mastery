aws_region                 = "ap-south-1"
key_name                   = "k8s-practice"
bastion_instance_type      = "t3.micro"
controlplane_count         = 1
controlplane_instance_type = "t3.medium"
worker_count               = 2
worker_instance_type       = "t3.medium"
