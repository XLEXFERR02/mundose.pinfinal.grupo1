```
#                                       $$\                     $$$$$$$$\
#                                       $$ |                    $$ _____|
#  $$$$$$\$$$$\  $$\  $$\ $$$$$$$\ $$$$$$$ | $$$$$$\  $$$$$$$\  $$ |
#  $$  _$$  _$$\ $$ | $$ |$$  _$$\ $$  _$$ |$$  _$$\ $$  _____| $$$$$\
#  $$ / $$ / $$ |$$ | $$ |$$ | $$ |$$ / $$ |$$ / $$ |\$$$$$$\   $$  __|
#  $$ | $$ | $$ |$$ | $$ |$$ | $$ |$$ | $$ |$$ | $$ | \____$$\  $$ |
#  $$ | $$ | $$ |\$$$$$$ |$$ | $$ |\$$$$$$$|\$$$$$$ |$$$$$$$ |  $$$$$$$$\
#  \__| \__| \__| \_____/ \__| \__| \______| \____/  \_______/  \_______|
```

PIN Final – devops 2403
Profesor: Guazzardo, Marcelo
Grupo 1: Cabral, Damian Esteban, Ferreira, Alexander, Gonzalez, Claudio, Huataquispe Poma, Arnold, Rico, Cristian

Este repositorio contiene el Trabajo Práctico Final donde integramos diversos conceptos de DevOps y despliegue en AWS. A lo largo del proyecto utilizamos Terraform para gestionar infraestructura (EC2, EKS, etc.), configuramos GitHub Actions para automatizar la entrega y definimos servicios clave como NGINX, Prometheus, Grafana y el driver EBS CSI para almacenamiento en el clúster de Kubernetes.

En este README encontrarás una breve introducción sobre los tópicos principales:

GITHUB: Commits y manejo de repository secrets.
AWS: Configuraciones generales, IAM, billing, EC2 bastion y los archivos clave de Terraform (main.tf, providers.tf, variables, outputs…).
EKS: Despliegue y verificación de un clúster Kubernetes, incluyendo aspectos de permisos y configMap.
NGINX: Ejemplo de despliegue y validación de contenedores.
EBS CSI Driver: Instalación, permisos y troubleshooting al crear persistent volumes.
Prometheus: Instalación, configuración con NodePort y resolución de problemas con alertmanager.
Grafana: Deploy y validación de acceso.
Limpieza (CLEAN) y revisión final para controlar costos y topología en AWS.

ÍNDICE PRINCIPAL

- INTRODUCCIÓN
- GITHUB
  -- Commits
  -- Repository Secrets
- AWS
  -- Configuraciones generales
  --- IAM
  --- Billing and Cost Management
  --- Estructura de directorios
  -- EC2 (Bastion)
  --- KEY PAIR
  --- Otros archivos (user_data.sh, ec2-admin.json, .gitignore)
  --- TERRAFORM
  ---- main.tf, backend.tf, iam.tf, variables.tf, outputs.tf, providers.tf, terraform.tfvars
  --- GITHUB ACTIONS
  ----- Workflow, ejecución
  --- AWS (EC2)
  ---- Validación de instancia
  ---- Rol ec2-admin, acceso, Ubuntu Version, paquetes, Elastic IP
  -- EKS
  --- Despliegue, script crear_cluster.sh, preparación, verificaciones, permisos, configMap
  --- NGINX
  ----- Despliegue y comprobaciones
  --- EBS CSI Driver
  ----- Instalación, addon EBS, validación y troubleshooting de PVC
  --- MONITOREO
  ----- Prometheus (instalación, NodePort, alerta, port-forward)
  ----- Grafana (instalación, validación)
  ------ EKS Web y Dashboard
  -- CLEAN y REVISIÓN
  --- Conclusiones, topología general, billing
