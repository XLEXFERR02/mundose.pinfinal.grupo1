#!/bin/bash
# Configura el script para que se detenga si ocurre algún error,
# se usen variables no definidas o haya errores en pipelines.
set -euo pipefail

# ==============================================================================
# Crear el namespace para Grafana
# ==============================================================================
# Este comando crea el namespace "grafana" en Kubernetes.
kubectl create namespace grafana

# ==============================================================================
# Agregar el repositorio de Helm de Grafana y actualizar la caché
# ==============================================================================
# Agrega el repositorio de charts oficial de Grafana.
helm repo add grafana https://grafana.github.io/helm-charts
# Actualiza la caché de repositorios para tener la última versión del chart.
helm repo update

# ==============================================================================
# Instalar Grafana usando Helm
# ==============================================================================
# El siguiente comando instala Grafana en el namespace "grafana" utilizando el chart
# del repositorio "grafana/grafana". Se configuran los siguientes parámetros:
#
# --namespace grafana: Se instala en el namespace "grafana".
# --set persistence.storageClassName="gp2": Se establece "gp2" como StorageClass para la persistencia.
# --set persistence.enabled=true: Se habilita la persistencia de datos.
# --set adminPassword='xxxxxxxxx': Se define la contraseña de administrador de Grafana.
# --values ${HOME}/environment/grafana/grafana.yaml: Se cargan valores adicionales desde un archivo YAML.
# --set service.type=LoadBalancer: Se configura el servicio para que sea de tipo LoadBalancer.
helm install grafana grafana/grafana \
  --namespace grafana \
  --set persistence.storageClassName="gp2" \
  --set persistence.enabled=true \
  --set adminPassword='MSE!pinfinalG1.' \
  --values "${HOME}/environment/grafana/grafana.yaml" \
  --set service.type=LoadBalancer

echo "Instalación de Grafana completada en el namespace 'grafana'."


#helm show values grafana/grafana