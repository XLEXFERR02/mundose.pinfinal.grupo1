resource "aws_key_pair" "pin" {
  key_name   = var.key_name
  public_key = var.public_ssh_key
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security Group for Bastion Host"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.pin.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

   iam_instance_profile = aws_iam_instance_profile.ec2_admin_profile.name

  user_data = file("${path.module}/scripts/user_data.sh")

  tags = {
    Name = "bastion-host"
  }
}
