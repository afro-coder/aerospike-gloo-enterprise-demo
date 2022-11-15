#!/bin/bash


cat <<EOF | kubectl apply -f -
apiVersion: portal.gloo.solo.io/v1beta1
kind: Portal
metadata:
  name: petstore-portal
  namespace: default
spec:
  displayName: Petstore Portal
  description: The Gloo Portal for the Petstore API
  # Image formats PNG, JPG and GIF are supported. SVG format is NOT supported at this time.
  banner:
    fetchUrl: https://i.imgur.com/EXbBN1a.jpg
  favicon:
    fetchUrl: https://i.imgur.com/QQwlQG3.png
  primaryLogo:
    fetchUrl: https://i.imgur.com/hjgPMNP.png
  customStyling: {}
  staticPages: []

  domains:
  # If you are using Gloo Edge and the Gateway is listening on a port other than 80, 
  # you need to include a domain in this format: <DOMAIN>:<INGRESS_PORT> as we do below
  - petstore.example.com:8080
  - petstore.example.com

  # This will include all API product of the environment in the portal
  publishedEnvironments:
  - name: dev
    namespace: default

  # This allows users to view APIs without needing to log in
  allApisPublicViewable: true
EOF

kubectl get portal -n default petstore-portal -oyaml

curl --silent --resolve petstore.example.com:8080:127.0.0.1 "http://petstore.example.com:8080/api/pets"

