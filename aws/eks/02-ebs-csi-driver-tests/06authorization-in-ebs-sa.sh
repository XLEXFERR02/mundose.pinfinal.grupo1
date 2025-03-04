#Identificar los volumenes y estados que tienen en el  namespace prometheus
kubectl get pvc -n prometheus  
# Mostrar en detalle el estado del pvc afectado
kubectl describe pvc storage-prometheus-alertmanager-0 -n prometheus

#!/bin/bash
set -euo pipefail

# Variables (ajusta estos valores según tu entorno)
REGION="us-east-1"
CLUSTER_NAME="2403-g1-pin-final"
SERVICE_ACCOUNT="ebs-csi-controller-sa"
NAMESPACE="kube-system"
ROLE_NAME="AmazonEKS_EBS_CSI_DriverRole"

# Obtener el ID de cuenta
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# Obtener el proveedor OIDC del clúster (se quita el prefijo "https://")
OIDC_PROVIDER=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" --query "cluster.identity.oidc.issuer" --output text | sed 's/https:\/\///')

if [ -z "$OIDC_PROVIDER" ]; then
  echo "Error: No se pudo obtener el proveedor OIDC. Asegúrate de que el clúster esté creado con --with-oidc."
  exit 1
fi

echo "Cuenta: $ACCOUNT_ID"
echo "OIDC Provider: $OIDC_PROVIDER"

# Verificar si el rol ya existe
if aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
  echo "El rol ${ROLE_NAME} ya existe. Se utilizará este rol."
else
  echo "Creando el rol IAM ${ROLE_NAME}..."
  # Crear el archivo de política de confianza temporalmente
  cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT}"
        }
      }
    }
  ]
}
EOF

  aws iam create-role --role-name "${ROLE_NAME}" --assume-role-policy-document file://trust-policy.json

  echo "Adjuntando la política AmazonEBSCSIDriverPolicy al rol ${ROLE_NAME}..."
  aws iam attach-role-policy --role-name "${ROLE_NAME}" --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy

  # Limpieza: eliminar el archivo temporal de política de confianza
  rm trust-policy.json
fi

# Obtener el ARN del rol (ya existente o recién creado)
ROLE_ARN=$(aws iam get-role --role-name "${ROLE_NAME}" --query "Role.Arn" --output text)
echo "Usando el rol con ARN: ${ROLE_ARN}"

# Aplicar el patch al ServiceAccount para asociarlo con el rol
echo "Actualizando el ServiceAccount ${SERVICE_ACCOUNT} en el namespace ${NAMESPACE}..."
kubectl patch serviceaccount "${SERVICE_ACCOUNT}" -n "${NAMESPACE}" \
  -p "{\"metadata\":{\"annotations\":{\"eks.amazonaws.com/role-arn\": \"${ROLE_ARN}\"}}}"

echo "Verificando el ServiceAccount actualizado:"
kubectl get serviceaccount "${SERVICE_ACCOUNT}" -n "${NAMESPACE}" -o yaml
