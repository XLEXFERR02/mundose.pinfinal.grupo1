#!/bin/bash
set -euo pipefail

echo "Aplicando manifiesto para el Pod de Nginx..."
kubectl apply -f nginx-pod.yaml

echo "Aplicando manifiesto para el Service de Nginx..."
kubectl apply -f nginx-service.yaml

echo "Esperando que se asigne una IP pública al Service (esto puede tardar unos minutos)..."
# Espera hasta que se asigne una IP externa
while true; do
  EXTERNAL_IP=$(kubectl get svc nginx-service -n default --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  if [ -n "$EXTERNAL_IP" ]; then
    echo "El Service está disponible en: $EXTERNAL_IP (o su IP asociada)"
    break
  fi
  echo "Esperando 10 segundos para que se asigne la IP..."
  sleep 10
done

echo "Despliegue completado. Puedes acceder a Nginx desde Internet utilizando el hostname/IP asignado."
