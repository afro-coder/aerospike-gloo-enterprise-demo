## Aerospike and Gloo Enterprise Demo

- This will setup a Kind Cluster
- Requires kind, helm, kubectl, kubectx pre-installed

You'll need an Enterprise License for this, feel free to contact us for a trial license...

- Run `deploy.sh`
- Run `gloo-portal.sh`
- Apply the aerospike.yaml(You need to add a features.conf file as the secret)
- Run `api_product_1.sh`
- Run `api_portal_2.sh`
- Run `api_user_group_3.sh`
- Port forward the Gloo Gateway svc
```
k port-forward -n gloo-system svc/gateway-proxy  8080:80
```
This will configure the storage to use aerospike
- Run `aerospike-storage-cr.sh`

Restart the controller pod
kubectl rollout restart deployment -n gloo-portal gloo-portal-controller

https://docs.solo.io/gloo-portal/main/guides/portal_features/apikey_storage/
