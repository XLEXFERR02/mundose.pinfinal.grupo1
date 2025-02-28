data "aws_iam_role" "ec2_admin_role" {
  name = "ec2-admin"
}

data "aws_iam_instance_profile" "ec2_admin_profile" {
  name = "ec2-admin"
}

resource "aws_iam_policy" "ec2_admin_policy" {
  name        = "ec2-admin-policy"
  description = "Permisos para administrar EKS desde el bastion"
  policy      = file("${path.module}/policies/ec2-admin.json")
}

resource "aws_iam_role_policy_attachment" "attach_bastion_eks_policy" {
  role       = data.aws_iam_role.ec2_admin_role.name
  policy_arn = aws_iam_policy.ec2_admin_policy.arn
}
