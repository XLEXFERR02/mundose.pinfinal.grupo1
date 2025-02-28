resource "aws_iam_policy" "ec2_admin_policy" {
  name        = "ec2-admin-policy"
  description = "Permisos para administrar EKS desde el bastion"

  policy = file("${path.module}/policies/ec2-admin.json")
}

resource "aws_iam_role_policy_attachment" "attach_bastion_eks_policy" {
  role       = "ec2-admin"  # Si el rol ya existe en AWS, usa el nombre directamente
  policy_arn = aws_iam_policy.ec2_admin_policy.arn
}