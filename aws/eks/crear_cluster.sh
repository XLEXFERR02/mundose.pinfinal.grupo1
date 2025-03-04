#!/bin/bash
# Configura el script para que se detenga ante errores (-e), variables no definidas (-u)
# y que los errores en pipelines se propaguen (-o pipefail).
set -euo pipefail

# ================================
# Configuración de variables
# ================================
# Define el nombre del clúster que se creará.
CLUSTER_NAME="2403-g1-pin-final"
# Define la región de AWS donde se creará el clúster.
AWS_REGION="us-east-1"
# Define el nombre de la clave SSH que se usará para acceder a los nodos. Asegúrate de que exista en tu cuenta.
SSH_KEY="pin"
# Define las zonas de disponibilidad en las que se desplegarán los nodos.
ZONES="us-east-1a,us-east-1b,us-east-1c"
# Define el número de nodos (workers) que tendrá el clúster.
NODE_COUNT=3
# Define el tipo de instancia para los nodos.
NODE_TYPE="t2.small"

#eksctl delete cluster --region=us-east-1 --name=2403-g1-pin-final-cluster
#aws cloudformation update-termination-protection --stack-name eksctl-2403-g1-pin-final-cluster --no-enable-termination-protection --region us-east-1
#aws cloudformation delete-stack --stack-name eksctl-2403-g1-pin-final-cluster --region us-east-1
#aws cloudformation describe-stacks --stack-name eksctl-2403-g1-pin-final-cluster --region us-east-1

# ================================
# Funciones de utilidad
# ================================
# Función para comprobar si un comando existe en el sistema.
# Se utiliza 'command -v' para buscar la ruta del comando; si no se encuentra, retorna un error.
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# ================================
# Verificaciones previas
# ================================
# Verificar si el AWS CLI está instalado. Si no, muestra un mensaje de error y termina el script.
if ! command_exists aws; then
  echo "Error: aws CLI no está instalado. Por favor, instálalo antes de continuar." >&2
  exit 1
fi

# Verificar si eksctl está instalado. Si no, muestra un mensaje de error y termina el script.
if ! command_exists eksctl; then
  echo "Error: eksctl no está instalado. Por favor, instálalo antes de continuar." >&2
  exit 1
fi

# Verificar que las credenciales de AWS estén configuradas correctamente usando 'aws sts get-caller-identity'.
# Si la comprobación falla, se solicita al usuario que ejecute 'aws configure'.
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "Por favor, ejecuta 'aws configure' para establecer credenciales válidas." >&2
  exit 1
fi

# Mensaje informativo para indicar que las credenciales han sido verificadas y se procederá a la creación del clúster.
echo "Credenciales verificadas. Procediendo con la creación del clúster '$CLUSTER_NAME' en la región '$AWS_REGION'."

# ================================
# Creación del clúster con eksctl
# ================================
# Se utiliza 'eksctl create cluster' con varios parámetros:
#   --name: asigna el nombre del clúster.
#   --region: define la región de AWS.
#   --nodes: establece la cantidad de nodos que se desplegarán.
#   --node-type: define el tipo de instancia para los nodos.
#   --with-oidc: habilita la integración con OIDC.
#   --ssh-access: habilita el acceso SSH a los nodos.
#   --ssh-public-key: especifica la clave SSH a utilizar.
#   --managed: indica que los nodos serán administrados (managed node groups).
#   --full-ecr-access: otorga acceso completo a ECR (Elastic Container Registry).
#   --zones: define las zonas de disponibilidad a utilizar.
if eksctl create cluster \
    --name "$CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --nodes "$NODE_COUNT" \
    --node-type "$NODE_TYPE" \
    --version "1.32" \
    --with-oidc \
    --ssh-access \
    --ssh-public-key "$SSH_KEY" \
    --managed \
    --full-ecr-access \
    --zones "$ZONES"; then
  # Si el comando se ejecuta correctamente, se muestra un mensaje de éxito.
  echo "Configuración del clúster completada con éxito mediante eksctl."
else
  # Si ocurre algún error durante la creación, se muestra un mensaje de error y se termina el script.
  echo "La configuración del clúster falló durante la ejecución de eksctl." >&2
  exit 1
fi