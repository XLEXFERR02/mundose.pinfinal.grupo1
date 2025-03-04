#!/bin/bash
set -euo pipefail

# Verificar que se haya pasado el nombre del rol como argumento
if [ "$#" -ne 1 ]; then
  echo "Uso: $0 <NODE_GROUP_ROLE>"
  exit 1
fi

NODE_GROUP_ROLE="$1"
# ARN de la política administrada de Amazon EBS CSI Driver (en la partición estándar)
POLICY_ARN="arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"

echo "Adjuntando la política $POLICY_ARN al rol $NODE_GROUP_ROLE..."

# Adjuntar la política al rol
aws iam attach-role-policy --role-name "$NODE_GROUP_ROLE" --policy-arn "$POLICY_ARN"

echo "Verificando que la política se adjuntó correctamente..."
aws iam list-attached-role-policies --role-name "$NODE_GROUP_ROLE" \
  --query "AttachedPolicies[?PolicyArn=='$POLICY_ARN']" --output table

echo "La política AmazonEBSCSIDriverPolicy se ha adjuntado exitosamente al rol $NODE_GROUP_ROLE."
