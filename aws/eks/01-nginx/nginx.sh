#!/bin/bash
set -euo pipefail

# Función de ayuda
usage() {
  echo "Uso: $0 [-d]"
  echo "  -d   Modo delete: elimina el Deployment y el Service de Nginx en el namespace 'nginx' en lugar de crearlos."
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

NAMESPACE="nginx"
POD_NAME="nginx-deployment"
SERVICE_NAME="nginx-service"

# Archivos YAML originales y temporales (para corregir el namespace)
POD_YAML_ORIG="nginx-deployment.yaml"
SERVICE_YAML_ORIG="nginx-service.yaml"
POD_YAML_TEMP="nginx-deployment-temp.yaml"
SERVICE_YAML_TEMP="nginx-service-temp.yaml"

# Crear el namespace si no existe
if ! kubectl get ns "$NAMESPACE" >/dev/null 2>&1; then
  echo "El namespace '$NAMESPACE' no existe. Creándolo..."
  kubectl create namespace "$NAMESPACE"
fi

# Modificar los YAML para que usen el namespace "nginx"
# Se reemplaza "namespace: default" por "namespace: nginx" si está definido en el YAML
if grep -q "namespace:" "$POD_YAML_ORIG"; then
  sed "s/namespace:[[:space:]]*__namespace__/namespace: ${NAMESPACE}/g" "$POD_YAML_ORIG" > "$POD_YAML_TEMP"
else
  cp "$POD_YAML_ORIG" "$POD_YAML_TEMP"
fi

if grep -q "namespace:" "$SERVICE_YAML_ORIG"; then
  sed "s/namespace:[[:space:]]*__namespace__/namespace: ${NAMESPACE}/g" "$SERVICE_YAML_ORIG" > "$SERVICE_YAML_TEMP"
else
  cp "$SERVICE_YAML_ORIG" "$SERVICE_YAML_TEMP"
fi

if [ "$DELETE_MODE" = true ]; then
  echo "Modo delete activado: eliminando el Deployment y el Service de Nginx en el namespace '$NAMESPACE'..."
  kubectl delete -f "$POD_YAML_TEMP" --namespace "$NAMESPACE" --ignore-not-found
  kubectl delete -f "$SERVICE_YAML_TEMP" --namespace "$NAMESPACE" --ignore-not-found
  kubectl delete namespace "$NAMESPACE"
  echo "Recursos eliminados."
  # Eliminar archivos temporales
  rm -f "$POD_YAML_TEMP" "$SERVICE_YAML_TEMP"
  exit 0
fi

# Despliegue y validación

echo "Aplicando manifiesto para el Pod de Nginx en el namespace '$NAMESPACE'..."
kubectl apply -f "$POD_YAML_TEMP" --namespace "$NAMESPACE"

echo "Aplicando manifiesto para el Service de Nginx en el namespace '$NAMESPACE'..."
kubectl apply -f "$SERVICE_YAML_TEMP" --namespace "$NAMESPACE"

echo "Esperando a que al menos un Pod con la etiqueta 'app=nginx' alcance el estado 'Running' en el namespace '$NAMESPACE'..."
while true; do
  POD_STATUS=$(kubectl get pods -n "$NAMESPACE" -l app=nginx --output jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
  if [ "$POD_STATUS" = "Running" ]; then
    echo "Al menos un Pod con la etiqueta 'app=nginx' está en estado Running."
    break
  elif [ "$POD_STATUS" = "NotFound" ]; then
    echo "Ningún Pod con la etiqueta 'app=nginx' encontrado. Esperando 5 segundos..."
  else
    echo "Estado actual del primer Pod: $POD_STATUS. Esperando 5 segundos..."
  fi
  sleep 5
done

echo "Esperando que se asigne una IP/hostname público al Service '$SERVICE_NAME' en el namespace '$NAMESPACE'..."
# Espera hasta que se asigne una IP/hostname al Service
while true; do
  EXTERNAL_IP=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" --output jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
  if [ -z "$EXTERNAL_IP" ]; then
    EXTERNAL_IP=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" --output jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  fi
  if [ -n "$EXTERNAL_IP" ]; then
    echo "El Service '$SERVICE_NAME' está disponible en: $EXTERNAL_IP"
    break
  fi
  echo "Esperando 10 segundos para que se asigne la IP/hostname..."
  sleep 10
done

echo "Despliegue completado en el namespace '$NAMESPACE'. Puedes acceder a Nginx desde Internet utilizando el hostname/IP asignado."

# Limpieza de archivos temporales
rm -f "$POD_YAML_TEMP" "$SERVICE_YAML_TEMP"
