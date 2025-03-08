#!/bin/bash
set -euo pipefail

####
# - Permite especificar el perfil (usuario iam) mediante la opción -u.
# - Verifica si el perfil existe (usando aws configure list-profiles).
# - Si no existe, ejecuta aws configure --profile <usuario> para que se configure.
# - Actualiza el kubeconfig para el cluster EKS asumiendo el rol indicado, y crea un contexto con un alias.

# Función para mostrar el uso del script
usage() {
  echo "Uso: $0 -u <usuario> [-c <cluster_name>] [-r <region>] [-a <alias>] [-R <role_arn>]"
  echo ""
  echo "  -u   Nombre del usuario IAM (AWS CLI profile) a utilizar (obligatorio)."
  echo "  -c   Nombre del cluster EKS (por defecto: 2403-g1-pin-final)."
  echo "  -r   Región AWS (por defecto: us-east-1)."
  echo "  -a   Alias para el contexto kubeconfig (por defecto: <usuario>-eks)."
  echo "  -R   ARN del rol a asumir (por defecto: arn:aws:iam::194722402815:role/EKSIAMAdminAccessRole)."
  exit 1
}

# Valores por defecto
CLUSTER_NAME="2403-g1-pin-final"
REGION="us-east-1"
ROLE_ARN="arn:aws:iam::194722402815:role/EKSIAMAdminAccessRole"

# Procesar opciones
while getopts ":u:c:r:a:R:" opt; do
  case ${opt} in
    u )
      PROFILE="$OPTARG"
      ;;
    c )
      CLUSTER_NAME="$OPTARG"
      ;;
    r )
      REGION="$OPTARG"
      ;;
    a )
      ALIAS="$OPTARG"
      ;;
    R )
      ROLE_ARN="$OPTARG"
      ;;
    \? )
      echo "Opción inválida: -$OPTARG" >&2
      usage
      ;;
    : )
      echo "La opción -$OPTARG requiere un argumento." >&2
      usage
      ;;
  esac
done

# Verificar que el parámetro obligatorio -u (usuario) se haya proporcionado
if [ -z "${PROFILE:-}" ]; then
  echo "El parámetro -u <usuario> es obligatorio."
  usage
fi

# Si no se especificó alias, usar "<usuario>-eks"
if [ -z "${ALIAS:-}" ]; then
  ALIAS="${PROFILE}-eks"
fi

# Verificar si el perfil existe
if ! aws configure list-profiles | grep -q "^${PROFILE}$"; then
  echo "El perfil '${PROFILE}' no existe. Ejecutando 'aws configure --profile ${PROFILE}'..."
  aws configure --profile "${PROFILE}"
fi

echo "Actualizando kubeconfig para el cluster '${CLUSTER_NAME}' en la región '${REGION}'..."
echo "Usando el perfil '${PROFILE}' y asumiendo el rol '${ROLE_ARN}'"

aws eks update-kubeconfig \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --profile "$PROFILE" \
  --role-arn "$ROLE_ARN" \
  --alias "$ALIAS"

echo "Verificando los contextos existentes"
kubectl config get-contexts   #kubectl config current-context

echo "Cambiando al contexto '${ALIAS}'..."
kubectl config use-context "$ALIAS"

echo "Verificando acceso al cluster con 'kubectl get nodes'..."
kubectl get nodes

echo "El kubeconfig se ha actualizado y el rol ha sido asumido correctamente en el contexto '${ALIAS}'."
