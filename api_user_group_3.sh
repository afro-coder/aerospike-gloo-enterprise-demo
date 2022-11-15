#!/bin/bash

# Install the apache2-utils if you don't already have them
sudo apt install apache2-utils -y

# Generate the bcrypt hash with cost of 10
pass=$(htpasswd -bnBC 10 "" mysecurepassword | tr -d ':\n')

# Store the hash as a Kubernetes Secret
kubectl create secret generic dev1-password \
  -n gloo-portal --type=opaque \
  --from-literal=password=$pass


cat << EOF | kubectl apply -f-
apiVersion: portal.gloo.solo.io/v1beta1
kind: User
metadata:
  name: dev1
  namespace: gloo-portal
spec:
  accessLevel: {}
  basicAuth:
    passwordSecretKey: password
    passwordSecretName: dev1-password
    passwordSecretNamespace: gloo-portal
  username: dev1
EOF

kubectl get user dev1 -n gloo-portal -oyaml

cat << EOF | kubectl apply -f-
apiVersion: portal.gloo.solo.io/v1beta1
kind: Group
metadata:
  name: developers
  namespace: gloo-portal
spec:
  displayName: developers
  userSelector:
    matchLabels:
      groups.portal.gloo.solo.io/gloo-portal.developers: "true"
EOF

kubectl get group developers -n gloo-portal -oyaml

kubectl label user dev1 -n gloo-portal groups.portal.gloo.solo.io/gloo-portal.developers="true"

kubectl get group developers -n gloo-portal -oyaml

cat << EOF | kubectl apply -f-
apiVersion: portal.gloo.solo.io/v1beta1
kind: Environment
metadata:
  name: dev
  namespace: default
spec:
  domains:
  - api.example.com
  # If you are using Gloo Edge and the Gateway is listening on a port other than 80,
  # you need to include a domain in this format: <DOMAIN>:<PORT>.
  # In this example we expect the Gateway to listen on port 32000.
  - api.example.com:32000
  - api.example.com:8080

  displayInfo:
    description: This environment is meant for developers to deploy and test their APIs.
    displayName: Development
  parameters:
    usagePlans:
      basic:
        displayName: Basic plan with API key auth
        authPolicy:
          apiKey: { }
        rateLimit:
          requestsPerUnit: 3
          unit: MINUTE
  apiProducts:
  - namespaces:
    - "*"
    labels:
    - key: app
      operator: Equals
      values:
      - petstore
    versions:
      tags:
      - stable
    usagePlans:
    - basic
EOF


cat << EOF | kubectl apply -f-
apiVersion: portal.gloo.solo.io/v1beta1
kind: Group
metadata:
  name: developers
  namespace: gloo-portal
spec:
  displayName: developers
  # AccessLevel determines the resources the group has access to,
  # including APIProducts and Portals.
  accessLevel:
    apis:
    - products:
        namespaces:
        - "*"
        labels:
        - key: app
          operator: Equals
          values:
          - petstore
      environments:
        namespaces:
        - "*"
      usagePlans:
      - basic
    portals:
    - name: petstore-portal
      namespace: default
  userSelector:
    matchLabels:
      groups.portal.gloo.solo.io/gloo-portal.developers: "true"
EOF
