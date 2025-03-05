#!/bin/bash
set -euo pipefail

# Variables de configuración
NAMESPACE="kube-system"
CONFIGMAP_NAME="aws-auth"
NEW_CONFIG_FILE="aws-auth-new.yaml"
BACKUP_FILE="aws-auth-backup.yaml"
TEMP_CURRENT_CONFIG="aws-auth-current.yaml"

# 1. Respaldar la configuración actual
echo "Respaldando el ConfigMap ${CONFIGMAP_NAME}..."
kubectl get configmap ${CONFIGMAP_NAME} -n ${NAMESPACE} -o yaml > ${BACKUP_FILE}
echo "Respaldo guardado en ${BACKUP_FILE}"

# 2. Obtener la configuración actual en un archivo temporal para el diff
kubectl get configmap ${CONFIGMAP_NAME} -n ${NAMESPACE} -o yaml > ${TEMP_CURRENT_CONFIG}
echo "Configuración actual del ConfigMap ${CONFIGMAP_NAME}:"
cat ${TEMP_CURRENT_CONFIG}

# 3. Mostrar el diff entre la configuración actual y el nuevo archivo
echo "Comparando la configuración actual con ${NEW_CONFIG_FILE}..."
if diff -u ${TEMP_CURRENT_CONFIG} ${NEW_CONFIG_FILE}; then
  echo "No se encontraron diferencias."
else
  echo "Diferencias encontradas."
fi

# 4. Preguntar si se desean aplicar los cambios
read -rp "¿Desea aplicar la nueva configuración (s/n)? " RESP
if [[ "${RESP}" =~ ^[Ss] ]]; then
  echo "Aplicando la nueva configuración al ConfigMap ${CONFIGMAP_NAME}..."
  kubectl apply -f ${NEW_CONFIG_FILE}
  echo "La nueva configuración del ConfigMap ${CONFIGMAP_NAME} ha sido aplicada correctamente."
else
  echo "No se aplicaron cambios."
fi

# Limpieza del archivo temporal
rm -f ${TEMP_CURRENT_CONFIG}

# (Opcional) Abrir el editor para editar el ConfigMap manualmente
#kubectl edit -n ${NAMESPACE} configmap/${CONFIGMAP_NAME}

# Comentario original del mapUsers (para referencia)
#  mapUsers: |
#    - groups:
#    - system:masters
#      userarn:  <arn:aws:iam::xxxx:user/xxx
#      username: xxx
