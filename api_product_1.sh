#!/bin/bash

# Create API product https://docs.solo.io/gloo-portal/main/guides/getting_started/part_1/
# API doc, api product, environment


kubectl apply -n default -f \
  https://raw.githubusercontent.com/solo-io/gloo/v1.9.0-beta8/example/petstore/petstore.yaml
kubectl -n default rollout status deployment petstore

cat <<EOF | kubectl apply -f -
apiVersion: portal.gloo.solo.io/v1beta1
kind: APIDoc
metadata:
  name: petstore-schema
  namespace: default
spec:
  ## specify the type of schema provided in this APIDoc.
  ## openApi is only option at this time.
  openApi:
    content:
      # we use a fetchUrl here to tell the Gloo Portal
      # to fetch the schema contents directly from the petstore service.
      # 
      # configmaps and inline strings are also supported.
      fetchUrl: http://petstore.default:8080/swagger.json

EOF

kubectl get apidoc -n default petstore-schema -oyaml

cat << EOF | kubectl apply -f -
apiVersion: gloo.solo.io/v1
kind: Upstream
metadata:
  name: default-petstore-8080
  namespace: gloo-system
spec:
  kube:
    serviceName: petstore
    serviceNamespace: default
    servicePort: 8080
EOF

cat << EOF | kubectl apply -f -
apiVersion: portal.gloo.solo.io/v1beta1
kind: APIProduct
metadata:
  name: petstore-product
  namespace: default
  labels:
    app: petstore
spec:
  displayInfo:
    description: Petstore Product
    title: Petstore Product
  # Specify one or more version objects that will each include a list
  # of APIs that compose the version and routing for the version  
  versions:
  - name: v1
    apis:
    # Specify the API Doc(s) that will be included in the Product
    # each specifier can include a list of individual operations
    # to import from the API Doc.
    #
    # If none are listed, all the 
    # operations will be imported from the doc. 
    - apiDoc:
        name: petstore-schema
        namespace: default
    # Each imported operation must have a 'route' associated with it.
    # Here we define a route that will be used by default for all the selected APIProduct version operations.
    # You can also set overrides for this route on each individual operation.
    # A route must be provided for every Operation to enable routing for an API Product.  
    gatewayConfig:
      route:
        inlineRoute:
          backends:
          - upstream:
              name: default-petstore-8080
              namespace: gloo-system
    # You can add arbitrary tags to an APIProduct version. 
    # Users will be able to search for APIs based on the available tags when they log into a portal application.
    tags:
      stable: {}
EOF


kubectl get apiproducts.portal.gloo.solo.io -n default petstore-product -ojsonpath='{.status.state}'


kubectl get apiproducts.portal.gloo.solo.io -n default petstore-product -oyaml

cat << EOF | kubectl apply -f -
apiVersion: portal.gloo.solo.io/v1beta1
kind: Environment
metadata:
  name: dev
  namespace: default
spec:
  domains:
  # If you are using Gloo Edge and the Gateway is listening on a port other than 80, 
  # you need to include a domain in this format: <DOMAIN>:<PORT>.
  - api.example.com
  - api.example.com:8080
  displayInfo:
    description: This environment is meant for developers to deploy and test their APIs.
    displayName: Development
  # This field will determine which APIProduct versions are published in this Environment.
  # Each entry represents a selector which contains criteria to match the desired API product versions.
  # Here we use a single selector that will match all APIProducts with the 'app: petstore' label in all namespaces;
  # Additionally, we want to select only version of these APIProducts that contain the 'stable' tag.
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
EOF

kubectl get environment -n default dev -ojsonpath='{.status.state}'

kubectl get environments.portal.gloo.solo.io -n default dev -oyaml

#export INGRESS_HOST=127.0.0.1
#export INGRESS_PORT=$(kubectl -n gloo-system get service gateway-proxy -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

curl -v "http://localhost:8080/api/pets" -H "Host: api.example.com"
