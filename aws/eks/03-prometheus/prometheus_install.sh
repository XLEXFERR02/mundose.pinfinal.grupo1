#!/bin/bash
set -euo pipefail

usage() {
  echo "Uso: $0 [-d]"
  echo "  -d   Modo delete: elimina la instalación de Prometheus y el namespace 'prometheus'."
  exit 1
}

# Procesar parámetros
DELETE_MODE=false
while getopts ":d" opt; do
  case ${opt} in
    d )
      DELETE_MODE=true
      ;;
    \? )
      usage
      ;;
  esac
done

NAMESPACE="prometheus"
RELEASE_NAME="prometheus"

if [ "$DELETE_MODE" = true ]; then
  echo "Modo delete activado: eliminando la instalación de Prometheus..."
  helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE" || echo "La release '$RELEASE_NAME' no se encontró."
  kubectl delete namespace "$NAMESPACE" --ignore-not-found
  echo "El entorno de Prometheus ha sido eliminado."
  exit 0
fi

# Agregar el repositorio de Helm de Prometheus Community y actualizarlo
echo "Agregando el repositorio de Prometheus Community..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Crear el namespace 'prometheus' si no existe
echo "Creando el namespace '$NAMESPACE'..."
kubectl create namespace "$NAMESPACE" || echo "El namespace '$NAMESPACE' ya existe."

# Instalar Prometheus usando el chart de prometheus-community
echo "Instalando Prometheus en el namespace '$NAMESPACE'..."
helm install "$RELEASE_NAME" prometheus-community/prometheus \
  --namespace "$NAMESPACE" \
  --set alertmanager.persistentVolume.storageClass="gp2" \
  --set server.persistentVolume.storageClass="gp2" \
  --set server.service.type="NodePort" \
  --set server.service.nodePort=32000

# Esperar a que los Pods se encuentren en estado Running, con timeout de 60 segundos
TIMEOUT=60
WAIT_INTERVAL=10
elapsed=0
echo "Esperando a que todos los Pods en el namespace '$NAMESPACE' estén en estado 'Running'..."
while true; do
  NOT_RUNNING=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase!=Running --no-headers | wc -l)
  if [ "$NOT_RUNNING" -eq 0 ]; then
    echo "Todos los Pods están en estado 'Running'."
    break
  fi
  if [ "$elapsed" -ge "$TIMEOUT" ]; then
    echo "Timeout: No se pudieron levantar todos los Pods en $TIMEOUT segundos. Revisar manualmente."
    kubectl get all -n prometheus
    exit 1
  fi
  echo "Algunos Pods no están Running. Esperando $WAIT_INTERVAL segundos..."
  sleep $WAIT_INTERVAL
  elapsed=$((elapsed + WAIT_INTERVAL))
done

# Mostrar el estado de los recursos creados en el namespace
echo "Mostrando el estado de los recursos creados en el namespace '$NAMESPACE':"
kubectl get all -n "$NAMESPACE"

# Mostrar información de los nodos y sus IPs
echo "Mostrando la lista de nodos y sus IPs:"
kubectl get nodes -o wide

# Mostrar información del servicio para verificar el NodePort
echo "Mostrando la información del servicio del Prometheus Server:"
kubectl get svc -n "$NAMESPACE" | grep -i nodeport

echo "Prometheus se ha instalado correctamente y todos los recursos están en estado saludable."
echo "Recuerda que, para acceder al servicio desde fuera, es posible que necesites actualizar el grupo de seguridad de los nodos para permitir el tráfico en el puerto 32000."
