#!/bin/bash
set -euo pipefail

usage() {
  echo "Uso: $0 [-d]"
  echo "  -d   Modo delete: elimina los recursos (StorageClass, PVC y Pod) creados para la prueba."
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

# Variables de configuración
NAMESPACE="default"
STORAGECLASS_YAML="02-storageclass.yaml"
PVC_YAML="03-pvc.yaml"
POD_YAML="04-pod-ebs-test.yaml"

PVC_NAME="test-ebs-pvc"
POD_NAME="test-ebs-pod"
SC_NAME="ebs-sc-gp3"

if [ "$DELETE_MODE" = true ]; then
  echo "Modo delete activado: eliminando StorageClass, PVC y Pod de la prueba..."

  # Eliminar recursos en este orden (el Pod y PVC dependen del StorageClass)
  kubectl delete -f "$POD_YAML" --namespace "$NAMESPACE" --ignore-not-found
  kubectl delete -f "$PVC_YAML" --namespace "$NAMESPACE" --ignore-not-found
  kubectl delete -f "$STORAGECLASS_YAML" --namespace "$NAMESPACE" --ignore-not-found
  
  echo "Recursos eliminados."
  exit 0
fi

# Despliegue de recursos
echo "Aplicando manifiesto para el StorageClass..."
kubectl apply -f "$STORAGECLASS_YAML"

echo "Aplicando manifiesto para el PersistentVolumeClaim..."
kubectl apply -f "$PVC_YAML" --namespace "$NAMESPACE"

echo "Aplicando manifiesto para el Pod de prueba..."
kubectl apply -f "$POD_YAML" --namespace "$NAMESPACE"

# Validación del PVC
echo "Validando que el PVC '$PVC_NAME' esté en estado 'Bound'..."
while true; do
  PVC_STATUS=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" --output jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
  if [ "$PVC_STATUS" = "Bound" ]; then
    echo "El PVC '$PVC_NAME' se encuentra en estado 'Bound'."
    break
  fi
  echo "Estado actual del PVC: $PVC_STATUS. Esperando 5 segundos..."
  sleep 5
done

# Validación del Pod
echo "Validando que el Pod '$POD_NAME' esté en estado 'Running'..."
while true; do
  POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" --output jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
  if [ "$POD_STATUS" = "Running" ]; then
    echo "El Pod '$POD_NAME' se encuentra en estado 'Running'."
    break
  fi
  echo "Estado actual del Pod: $POD_STATUS. Esperando 5 segundos..."
  sleep 5
done

# Mostrar recursos creados
echo "Mostrando los recursos creados en el namespace '$NAMESPACE':"
echo "StorageClass:"
kubectl get sc "$SC_NAME" -o wide || echo "No se encontró StorageClass '$SC_NAME'"
echo
echo "PersistentVolumeClaim:"
kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" -o wide
echo
echo "Pod:"
kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o wide

echo "Despliegue completado. Puedes acceder a Nginx utilizando el Service (si está expuesto) o verificar el contenido en el Pod."
