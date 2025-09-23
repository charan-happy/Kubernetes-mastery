resource "aws_iam_user" "k8s_terraform_user" {
  name = "k8s-terraform-admin"
}


# Custom IAM policy with permissions for networking, EC2, IAM, and S3
resource "aws_iam_policy" "k8s_policy" {
  name        = "k8s-terraform-policy"
  description = "Policy for managing Kubernetes infrastructure"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "iam:*",
          "eks:*",
          "autoscaling:*",
          "s3:*",
          "cloudwatch:*",
          "logs:*",
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      }
    ]
  })
}


# Attach policy to user
resource "aws_iam_user_policy_attachment" "k8s_user_attach" {
  user       = aws_iam_user.k8s_terraform_user.name
  policy_arn = aws_iam_policy.k8s_policy.arn
}

# Create access key for IAM user
resource "aws_iam_access_key" "k8s_access_key" {
  user = aws_iam_user.k8s_terraform_user.name
}