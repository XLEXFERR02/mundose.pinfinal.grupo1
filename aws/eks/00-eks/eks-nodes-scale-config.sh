#!/bin/bash
set -euo pipefail

# Valores por defecto
CLUSTER_NAME="2403-g1-pin-final"
NODEGROUP_NAME="ng-67b43adb"  # Puedes obtenerlo con: aws eks list-nodegroups --cluster-name 2403-g1-pin-final --query "nodegroups" --output text
MIN_NODES=0
MAX_NODES=3

# Función para mostrar el uso del script
usage() {
  echo "Uso: $0 -d <nodos-deseados> [-c <nombre-del-clúster>] [-n <nombre-del-nodegroup>] [-m <mínimo-de-nodos>] [-x <máximo-de-nodos>]"
  echo ""
  echo "Parámetros:"
  echo "  -d    Cantidad de nodos deseados (obligatorio)"
  echo "  -c    Nombre del clúster (opcional, por defecto: ${CLUSTER_NAME})"
  echo "  -n    Nombre del nodegroup (opcional, por defecto: ${NODEGROUP_NAME})"
  echo "  -m    Mínimo de nodos (opcional, por defecto: ${MIN_NODES})"
  echo "  -x    Máximo de nodos (opcional, por defecto: ${MAX_NODES})"
  exit 1
}

# Variable para la cantidad de nodos deseados
DESIRED_NODES=""

# Procesar parámetros con getopts
while getopts "c:n:d:m:x:" opt; do
  case ${opt} in
    c)
      CLUSTER_NAME="$OPTARG"
      ;;
    n)
      NODEGROUP_NAME="$OPTARG"
      ;;
    d)
      DESIRED_NODES="$OPTARG"
      ;;
    m)
      MIN_NODES="$OPTARG"
      ;;
    x)
      MAX_NODES="$OPTARG"
      ;;
    *)
      usage
      ;;
  esac
done

# Verificar que se haya pasado el parámetro obligatorio para la cantidad de nodos
if [ -z "${DESIRED_NODES}" ]; then
  echo "Error: Debes especificar la cantidad de nodos deseados con -d."
  usage
fi

# Mostrar los parámetros que se usarán
echo "Parámetros:"
echo "  Clúster:         ${CLUSTER_NAME}"
echo "  Nodegroup:       ${NODEGROUP_NAME}"
echo "  Nodos deseados:  ${DESIRED_NODES}"
echo "  Mínimo de nodos: ${MIN_NODES}"
echo "  Máximo de nodos: ${MAX_NODES}"
echo "!! Recordar si el numero de nodos actuales es mayor al de Nodos deseados seteado, el scale down puede demorar hasta 10minutos, para no demorar reducir el nro maximo de nodos"

# Construir el comando de escalado
SCALE_CMD="eksctl scale nodegroup --cluster ${CLUSTER_NAME} --name ${NODEGROUP_NAME} --nodes ${DESIRED_NODES}"

# Agregar opciones opcionales
if [ -n "${MIN_NODES}" ]; then
  SCALE_CMD+=" --nodes-min ${MIN_NODES}"
fi

if [ -n "${MAX_NODES}" ]; then
  SCALE_CMD+=" --nodes-max ${MAX_NODES}"
fi

echo "Ejecutando: ${SCALE_CMD}"
${SCALE_CMD}

# Monitorear el estado del escalado en vivo
echo "Esperando a que se complete el escalado..."
while true; do
  # Obtenemos el tamaño actual del nodegroup en formato JSON y extraemos el campo CurrentSize
  CURRENT_SIZE=$(eksctl get nodegroup --cluster "${CLUSTER_NAME}" --name "${NODEGROUP_NAME}" -o json | jq '.[0].CurrentSize')
  echo "Tamaño actual del nodegroup: ${CURRENT_SIZE} nodos."
  
  # Si el tamaño actual coincide con el deseado, salimos del bucle
  if [ "${CURRENT_SIZE}" -eq "${DESIRED_NODES}" ]; then
    echo "El escalado ha finalizado."
    break
  fi

  # Esperamos 10 segundos antes de volver a consultar
  sleep 10
done

echo "La operación de escalado se ha completado."
