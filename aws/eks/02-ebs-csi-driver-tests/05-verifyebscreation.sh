#!/bin/bash
set -euo pipefail

NAMESPACE="kube-system"
LABEL="app=ebs-csi-controller"

kubectl get pvc test-ebs-pvc
kubectl get pod test-ebs-pod
kubectl describe pvc test-ebs-pvc


echo "Buscando pods en el namespace '$NAMESPACE' con la etiqueta '$LABEL'..."
pods=$(kubectl get pods -n "$NAMESPACE" -l "$LABEL" -o jsonpath='{.items[*].metadata.name}')

if [ -z "$pods" ]; then
  echo "No se encontraron pods con la etiqueta '$LABEL' en el namespace '$NAMESPACE'."
  exit 1
fi

# Iterar sobre cada pod y mostrar sus logs
for pod in $pods; do
  echo -e "\n\n===== Logs para el pod: $pod ====="
  kubectl logs -n "$NAMESPACE" "$pod"
  echo -e "======================================\n"
done
