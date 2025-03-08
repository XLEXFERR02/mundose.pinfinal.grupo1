#!/bin/bash
set -euo pipefail
# Función de ayuda
usage() {
  echo "Uso: $0 -u <IAM_user>"
  exit 1
}
# =========================
# Procesar parámetros
# =========================
while getopts ":u:" opt; do
  case ${opt} in
    u )
      USER_NAME="$OPTARG"
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
# Si no se proporcionó el parámetro -u, usar valor por defecto "dcabral"
if [ -z "${USER_NAME:-}" ]; then
  USER_NAME="dcabral"
fi
# =========================
# Variables de configuración
# =========================
NAMESPACE="kube-system"
CONFIGMAP_NAME="aws-auth"
BACKUP_FILE="aws-auth-backup.yaml"
TEMP_CURRENT_CONFIG="aws-auth-current.yaml"
# Variables para el rol
ROLE_TEMPLATE="EKSIAMAdminAccessRole.yaml"
PROCESSED_ROLE_TEMPLATE="EKSIAMAdminAccessRole-processed.yaml"
STACK_NAME="EKSIAMAdminAccessRole-stack"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
ROLE_NAME="EKSIAMAdminAccessRole"

# Variable para el usuario (con el valor de -u)
USER_ARN="arn:aws:iam::${ACCOUNT_ID}:user/${USER_NAME}"

# =========================
# 0. Procesar la plantilla del rol reemplazando el marcador de ACCOUNT_ID
# =========================
echo "Procesando la plantilla del rol para reemplazar __ACCOUNT_ID__ con ${ACCOUNT_ID}..."
sed "s/__ACCOUNT_ID__/${ACCOUNT_ID}/g" "$ROLE_TEMPLATE" > "$PROCESSED_ROLE_TEMPLATE"

# =========================
# 1. Crear/Actualizar el rol desde la plantilla procesada (CloudFormation)
# =========================
echo "Creando/actualizando el rol '$ROLE_NAME' desde la plantilla '$PROCESSED_ROLE_TEMPLATE'..."
aws cloudformation deploy \
    --template-file "$PROCESSED_ROLE_TEMPLATE" \
    --stack-name "$STACK_NAME" \
    --capabilities CAPABILITY_NAMED_IAM

echo "Rol '$ROLE_NAME' creado/actualizado correctamente."
echo

# =========================
# 2. Respaldar la configuración actual de aws-auth
# =========================
echo "Respaldando el ConfigMap '${CONFIGMAP_NAME}'..."
kubectl get configmap ${CONFIGMAP_NAME} -n ${NAMESPACE} -o yaml > ${BACKUP_FILE}
echo "Respaldo guardado en '${BACKUP_FILE}'"
echo

# =========================
# 3. Obtener la configuración actual en un archivo temporal
# =========================
kubectl get configmap ${CONFIGMAP_NAME} -n ${NAMESPACE} -o yaml > ${TEMP_CURRENT_CONFIG}
echo "Configuración actual del ConfigMap ${CONFIGMAP_NAME}:"
cat ${TEMP_CURRENT_CONFIG}
echo

# =========================
# 4. Mostrar las líneas que se deben agregar
# =========================
echo "Debes agregar las siguientes líneas en la sección 'mapRoles:' dentro del ConfigMap '${CONFIGMAP_NAME}':"
echo
cat <<EOF
  - rolearn: arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}
    username: admin
    groups:
      - system:masters
EOF
echo
echo "Y en la sección 'mapUsers:' puedes agregar lo siguiente para el usuario '${USER_NAME}':"
echo
cat <<EOF
  - userarn: ${USER_ARN}
    username: ${USER_NAME}
    groups:
      - system:masters
EOF
echo
# =========================
# 5. Invitar al usuario a editar el ConfigMap manualmente
# =========================
read -rp "Presiona Enter para editar el ConfigMap ahora (o CTRL+C para cancelar)... " _
kubectl edit -n ${NAMESPACE} configmap/${CONFIGMAP_NAME}
# =========================
# Limpieza del archivo temporal
# =========================
rm -f ${TEMP_CURRENT_CONFIG}
echo "Proceso finalizado."
