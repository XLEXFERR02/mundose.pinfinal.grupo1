#!/bin/bash
set -euo pipefail

# Agregar el repositorio de Helm de Prometheus Community y actualizarlo
echo "Agregando el repositorio de Prometheus Community..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Crear el namespace 'prometheus'
echo "Creando el namespace 'prometheus'..."
kubectl create namespace prometheus || echo "El namespace 'prometheus' ya existe."

# Instalar Prometheus usando el chart de prometheus-community
echo "Instalando Prometheus en el namespace 'prometheus'..."
helm install prometheus prometheus-community/prometheus \
  --namespace prometheus \
  --set alertmanager.persistentVolume.storageClass="gp2" \
  --set server.persistentVolume.storageClass="gp2"
  --set server.service.type="NodePort" \
  --set server.service.nodePort=32000

echo "Prometheus se ha instalado correctamente."
