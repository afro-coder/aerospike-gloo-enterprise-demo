#!/bin/bash
# This example usually deploys to EKS on my end
# Can be done in kind too, using port-forwards.

# This script will setup Gloo Edge, modify GLOO_VERSION and GLOO_CLI_VERSION
# $ ./deploy.sh Context
# or default is assumed.
# Pre-requisites -> Helm, kubectx, kubectl, jq

#set -x

context=$1

#GLOO_VERSION=v1.10.1
export GLOO_VERSION="v1.13.0-beta9"
export GLOO_CLI_VERSION='v1.12.30'
echo $GLOO_VERSION

function ctx() {
kubectx $1
}

cluster_name="gloo-portal"
context="kind-gloo-portal"
echo -e "Creating a kind cluster\n";

cat <<EOF | kind create cluster --name $cluster_name --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
EOF
#ctx $context
# Install Metallb
#
#echo -e "Installing Metallb\n"
#kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.6/config/manifests/metallb-native.yaml

#ctx $context
#echo -e "Waiting for Metallb Pods\n"
# Namespace creation takes a few seconds
#sleep 15;
#kubectl wait pod -n metallb-system --all \
#    --for=condition=Ready --timeout=120s

# Configure Metallb uses host LAN/Wifi IP
#ipaddr="$(hostname -I|cut -d ' ' -f1)"


#echo -e "Metallb will use $ipaddr\n"

#kubectl --context=$context apply -f - <<EOF
#apiVersion: metallb.io/v1beta1
#kind: IPAddressPool
#metadata:
#  name: first-pool
#  namespace: metallb-system
#spec:
#  addresses:
#  - $ipaddr/32
#---
#apiVersion: metallb.io/v1beta1
#kind: L2Advertisement
#metadata:
#  name: example
#  namespace: metallb-system
#
#EOF

echo -e "Helming Glooee with logs enabled\n"
ctx $context
helm repo add glooe https://storage.googleapis.com/gloo-ee-helm
helm repo update

#helm install glooe glooe/gloo-ee --namespace gloo-system --create-namespace  --set-string license_key=$GQ   --version $GLOO_VERSION --set gloo-fed.enabled=false -f value-overrides.yaml
helm install $cluster_name glooe/gloo-ee --namespace gloo-system --create-namespace  --set-string license_key=$GQ   --version $GLOO_VERSION  -f value-overrides.yaml

echo -e "Waiting for Gloo System Pods to be up"
ctx $context
kubectl wait pod -n gloo-system --all \
    --for=condition=Ready --timeout=120s

#}
kubectl get upstreams -n gloo-system

