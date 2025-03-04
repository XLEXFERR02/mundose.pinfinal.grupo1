#!/bin/bash
# Habilita el modo "exit on error": si algún comando falla, el script se detiene inmediatamente.
set -e

# ================================
# Actualizar paquetes del sistema
# ================================
# Se actualizan los índices de paquetes y se actualizan los paquetes instalados a sus versiones más recientes.
apt-get update -y && apt-get upgrade -y

# ================================
# Instalar AWS CLI
# ================================
# AWS CLI es la herramienta de línea de comandos para interactuar con los servicios de Amazon Web Services.
apt install -y awscli

# ================================
# Instalar Docker
# ================================
# Docker es una plataforma para desarrollar, enviar y ejecutar aplicaciones en contenedores.
apt install -y docker.io
# Inicia el servicio de Docker.
systemctl start docker
# Habilita Docker para que se inicie automáticamente al arrancar el sistema.
systemctl enable docker
# Agrega el usuario 'ubuntu' al grupo 'docker' para poder ejecutar comandos Docker sin utilizar sudo.
usermod -aG docker ubuntu



# ================================
# Instalar kubectl
# ================================
# kubectl es la herramienta de línea de comandos para interactuar con clústeres de Kubernetes.
# Se descarga la última versión estable, se le da permisos de ejecución y se mueve a /usr/local/bin para que esté en el PATH.
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# ================================
# Instalar Helm
# ================================
# Helm es el gestor de paquetes para Kubernetes, que facilita la instalación y gestión de aplicaciones en clústeres.
# Se descarga y ejecuta el script oficial de instalación de Helm 3.
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ================================
# Instalar eksctl
# ================================
# eksctl es la herramienta de línea de comandos para crear y gestionar clústeres en Amazon EKS (Elastic Kubernetes Service).
# Se descarga la última versión, se extrae el binario y se mueve a /usr/local/bin para que esté disponible en el PATH.
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin
# Muestra la versión instalada de eksctl para confirmar que la instalación fue exitosa.
eksctl version

# ================================
# Instalar Docker Compose
# ================================
# Docker Compose es una herramienta para definir y ejecutar aplicaciones Docker de múltiples contenedores.
# Se descarga la última versión desde GitHub, se asignan permisos de ejecución y se verifica la instalación.
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

# ================================
# Instalar Terraform
# ================================
# Terraform es una herramienta de infraestructura como código, que permite definir, provisionar y gestionar infraestructura de forma declarativa.
# Se instalan dependencias necesarias, se agrega la llave GPG oficial de HashiCorp, se añade el repositorio oficial de HashiCorp,
# se actualizan los índices de paquetes y se instala Terraform.
apt-get install -y gnupg software-properties-common
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update -y && apt-get install -y terraform
# Muestra la versión instalada de Terraform para confirmar que la instalación fue exitosa.
terraform version


# ================================
# Instalar aws cli v2
# ================================

sudo apt install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&  unzip awscliv2.zip && sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
aws --version