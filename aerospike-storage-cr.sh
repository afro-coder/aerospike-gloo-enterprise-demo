#!/bin/bash
cat << EOF | kubectl apply -f-
apiVersion: portal.gloo.solo.io/v1beta1
kind: Storage
metadata:
  name: aerospike-storage
  namespace: gloo-system
spec:
  apikeyStorage:
    aerospike:
      hostname: aerospike.aerospike
      port: 3000
EOF

kubectl rollout restart deployment -n gloo-portal gloo-portal-controller

kubectl get -n default authconfig default-petstore-product-dev -oyaml
