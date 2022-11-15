#!/bin/bash

PORTAL_VERSION="1.3.0-beta16"

helm repo add gloo-portal https://storage.googleapis.com/dev-portal-helm
helm repo update

cat << EOF > gloo-values.yaml
glooEdge:
  enabled: true
licenseKey:
  secretRef:
    name: license
    namespace: gloo-system
    key: license-key
EOF

# Create the namespace and install the Helm chart
kubectl create namespace gloo-portal
helm install gloo-portal gloo-portal/gloo-portal -n gloo-portal --values gloo-values.yaml --version $PORTAL_VERSION

kubectl get all -n gloo-portal


