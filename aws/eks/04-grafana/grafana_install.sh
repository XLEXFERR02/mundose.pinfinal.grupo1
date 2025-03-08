#!/bin/bash
set -euo pipefail

usage() {
  echo "Uso: $0 [-d]"
  echo "  -d   Modo delete: elimina la instalación de Grafana y el namespace 'grafana'."
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

NAMESPACE="grafana"
RELEASE_NAME="grafana"
VALUES_FILE="${HOME}/environment/grafana/grafana.yaml"

# La contraseña de admin se toma de la variable de entorno GRAFANA_ADMIN_PASSWORD; 
# si no se define, se usa un valor por defecto.
ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-"MSE!pinfinalG1."}

if [ "$DELETE_MODE" = true ]; then
  echo "Modo delete activado: eliminando la instalación de Grafana..."
  helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE" || echo "La release '$RELEASE_NAME' no se encontró."
  kubectl delete namespace "$NAMESPACE" --ignore-not-found
  echo "El entorno de Grafana ha sido eliminado."
  exit 0
fi

# Crear el namespace 'grafana' si no existe
echo "Creando el namespace '$NAMESPACE'..."
kubectl create namespace "$NAMESPACE" || echo "El namespace '$NAMESPACE' ya existe."

# Agregar el repositorio de Helm de Grafana y actualizar la caché
echo "Agregando el repositorio de Helm de Grafana..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Instalar Grafana usando Helm
# --namespace grafana: Se instala en el namespace "grafana".
# --set persistence.storageClassName="gp2": Se establece "gp2" como StorageClass para la persistencia.
# --set persistence.enabled=true: Se habilita la persistencia de datos.
# --set adminPassword='xxxxxxxxx': Se define la contraseña de administrador de Grafana.
# --values ${HOME}/environment/grafana/grafana.yaml: Se cargan valores adicionales desde un archivo YAML.
# --set service.type=LoadBalancer: Se configura el servicio para que sea de tipo LoadBalancer.
echo "Instalando Grafana en el namespace '$NAMESPACE'..."
helm install "$RELEASE_NAME" grafana/grafana \
  --namespace "$NAMESPACE" \
  --set persistence.storageClassName="gp2" \
  --set persistence.enabled=true \
  --set adminPassword="$ADMIN_PASSWORD" \
  --values "$VALUES_FILE" \
  --set service.type="LoadBalancer"

# Esperar a que los Pods de Grafana estén en estado Running, con timeout de 60 segundos
TIMEOUT=60
INTERVAL=10
ELAPSED=0
echo "Esperando a que todos los Pods en el namespace '$NAMESPACE' estén en estado 'Running' (timeout ${TIMEOUT} segundos)..."
while true; do
  NOT_RUNNING=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase!=Running --no-headers | wc -l)
  if [ "$NOT_RUNNING" -eq 0 ]; then
    echo "Todos los Pods están en estado 'Running'."
    break
  fi
  if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "Timeout: No se pudieron levantar todos los Pods en $TIMEOUT segundos."
    exit 1
  fi
  echo "Algunos Pods no están Running. Esperando ${INTERVAL} segundos..."
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

# Mostrar los recursos creados en el namespace
echo "Mostrando el estado de los recursos creados en el namespace '$NAMESPACE':"
kubectl get all -n "$NAMESPACE"

# Mostrar la información de los nodos y sus IPs
echo "Mostrando la lista de nodos y sus IPs:"
kubectl get nodes -o wide

# Mostrar la información del servicio para verificar el NodePort
echo "Mostrando la información del servicio de Grafana:"
kubectl get svc -n "$NAMESPACE" | grep -i nodeport

echo "La instalación de Grafana se ha completado correctamente en el namespace '$NAMESPACE'."
echo "Recuerda que, para acceder al servicio desde fuera, es posible que necesites actualizar el grupo de seguridad de los nodos para permitir el tráfico en el puerto configurado."