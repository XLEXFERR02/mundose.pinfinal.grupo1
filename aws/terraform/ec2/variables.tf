variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "ami_id" {
  description = "AMI para Ubuntu 22.04 LTS"
  default     = "ami-0e1bed4f06a3b463d"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  default     = "t2.micro"
}

variable "key_name" {
  description = "Nombre del par de claves SSH"
  default     = "pin"
}

variable "public_ssh_key" {
  description = "Clave pública para SSH"
  type        = string
}
