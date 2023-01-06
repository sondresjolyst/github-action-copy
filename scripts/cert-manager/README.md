# Cert-manager - v1.1

We use [cert-manager](https://github.com/jetstack/cert-manager) to provide automatic SSL/TLS certificate generation in the cluster using Let's Encrypt.  
Depending on use case we can use it to either create certificates according to a crd manifest, or auto-create the certificate based on an ingress notation.  
For certificate management in general in Radix then please see [radix certificate management](https://github.com/equinor/radix-private/blob/master/docs/radix-platform/cert-management.md)

- [Overview](#overview)
- [Bootstrap](#bootstrap)
- [Teardown](#teardown)
- [Upgrade](#upgrade)
- [Credentials](#credentials)
- [Troubleshooting](#troubleshooting)


## Overview

Cert-manager will use the following resources to obtain certs

- A system user that allows it to edit DNS records (be able to handle ACME challenges)  
  - The credentials is stored in k8s secret `azure-dns-secret` in namespace `cert-manager`
- A private key used for certificate signing request (CSR)
  - Automatically generated by cert-manager
  - Stored in k8s secret `letsencrypt-prod` in namespace `cert-manager`
- `ClusterIssuer`
  - a cert-manager CR that has the configuration for how cert-manage should request tls certs
  - stored in default namespace
- `Certificate`
  - A cert-manager CR that has the configuration for a specific certificate. Example: `*.my-cluster.radix.equinor.com`
  - Custom `Certificate` CRs are stored in default namespace
  - Auto-generated `Certificate` CRs are stored in the same namespace as the `Ingress` that triggered their creation
  - The end result, a tls certificate, is stored in a k8s secrets of type `kubernetes.io/tls`

Cert-manager will watch for 
- `Certificate`(s) manifests
- `Ingress` that has a special annotation that instructs it to create a `Certificate` manifest


### How it works

Some resource will create an `Ingress` object (typically a custom ingress) that has a special annotation and a reference to an at the moment non-existing secret/tls-certificate.  

The Ingress-shim which is running in the cert-manager container will look for the correct annotation. If it finds an `Ingress` has that special annotation it will create a `Certificate` resource based on the data from the Ingress and the defaultIssuer* and defaultACME* settings (these settings are configured when installing the cert-manager).

When the cert-manager discover a new `Certificate` resource it will look at the provider and issuer references and try to find a matching ClusterIssuer. If it finds it it will use the settings from the ClusterIssuer to perform the certificate request process and hopefully retrieve a new signed certificate and put that into `{appName}-tls-secret`.

The DNS challenge verification process might take a minute or two to complete due to DNS propagation and caching.

Until this process is complete, and `{appName}-tls-secret` is populated, then the nginx-ingress will serve default 404 backend message.


## Bootstrap

Run script [`./bootstrap.sh`](./bootstrap.sh), see script header for more info.  

Bootstrap will
1. Read dns credentials from keyvault
1. Install cert-manager using the official helm chart
1. Transform the templated custom resources and apply them to the cluster
1. Annotate the tls secrets for `Kubed` syncronization

### Examples

```sh
# Example: Bootstrap a debug cluster

# Step 1: bootstrap aks
RADIX_ZONE_ENV=../radix-zone/radix_zone_dev.env CLUSTER_NAME=my-little-cluster ../aks/bootstrap.sh
# Step 2: bootstrap helm
RADIX_ZONE_ENV=../radix-zone/radix_zone_dev.env CLUSTER_NAME=my-little-cluster ../helm/bootstrap.sh
# Step 3: bootstrap cert-manager - note the use of STAGING to avoid messing with the LetsEncrypt weekly quota for real certs
RADIX_ZONE_ENV=../radix-zone/radix_zone_dev.env CLUSTER_NAME=my-little-cluster STAGING=true ./bootstrap.sh
# Done!
```


## Teardown

Run script [`./teardown.sh`](./teardown.sh), see script header for more info.  

Teardown will
1. Delete cert-manager and all related custom resources
1. It will _not_ delete the k8s tls secrets


## Upgrade

As long as cert-manager has the following status

> As this project is pre-1.0, we do not currently offer strong guarantees around our API stability.
>
> Notably, we may choose to make breaking changes to our API specification (i.e. the Issuer, ClusterIssuer and Certificate resources) in new minor releases.

then we need to handle deployment of cert-manager by scripts that are customized for that specific version.

Due to the high possibility of breaking changes you will need to 
1. Verify that the custom resources are still valid (old version vs new version)
1. Prepare bootstrap and removal script of new version
1. Remove any trace of old version from the cluster (use the teardown script for the old version)
1. When previous version is gone, install new version (use the bootstrap script for the new version)
1. Update this `README.md` title to show the new version number

The k8s tls secrets will be kept intact during this process as it does not belong to cert-manager.

Example:
```sh
# Upgrading cert-manager from v0.8.1 to v0.11.0 in cluster "my-little-cluster" that lives in radix-zone "dev"
# Step 1: Remove v0.8.1
RADIX_ZONE_ENV=../radix-zone/radix_zone_dev.env CLUSTER_NAME=my-little-cluster ./teardown_v0.8.1.sh
# Step 2: Install v0.11.0
RADIX_ZONE_ENV=../radix-zone/radix_zone_dev.env CLUSTER_NAME=my-little-cluster ./bootstrap.sh
```

## Credentials

`cert-manager` use dedicated service principal to work with the DNS.  
The name of this service principal is declared in var `AZ_SYSTEM_USER_DNS` in `radix_zone_*.env` config files

For updating/refreshing the credentials then 
1. Decide if you need to refresh the service principal credentials in AAD  
   Multiple components may use this service principal and refreshing credentials in AAD will impact all of them 
   - If yes to refresh credentials in AAD: 
     Refresh service principal credentials in AAD and update keyvault by following the instructions provided in doc ["service-principals-and-aad-apps/README.md"](../service-principals-and-aad-apps/README.md#refresh-component-service-principals-credentials)      
1. Update the credentials for `cert-manager` in the cluster by
   - (Normal usage) Executing the `..\install_base_components.sh` script as described in paragraph ["Deployment"](#deployment)
   - (Alternative for debugging) Run the [cert-manager bootstrap](./bootstrap) script
1. Restart the `cert-manager` pods so that the new replicas will read the updated k8s secrets
1. Done!


## Troubleshooting

1. If you just created a new cluster there may be an issue with conflict on DNS Zone entries for the ingress. They may point to the old cluster

- Make sure that the is no ingress in the old cluster competing with an ingress on the new cluster
- Delete the old DNS zone entries, and see that they reappear
- Set down TTL to 10 sec to ensure it is propagated quickly

2. The official `cert-manager`'s site provides guidelines on [how to debug](https://docs.cert-manager.io/en/latest/reference/orders.html) certificate-related issues

3. Sometimes there are issues on Letsencrypt's side, check its [status page](https://letsencrypt.status.io/)

4. These tools can be handy for debugging:

- https://letsdebug.net
- http://dnsviz.net/

5. Some URLs have a fake certificate
- Error creating new order :: too many certificates already issued for exact set of domains
- this error will show in the logs under: k logs --namespace cert-manager cert-manager-X-X
- https://letsencrypt.org/docs/rate-limits/
- check number of issued certs here: https://crt.sh/?q=dev.radix.equinor.com

Analysis of previous bugs/errors:
- [2019-08-13 No certificate for console.dev.radix.equinor.com.](https://github.com/equinor/radix-private/blob/master/docs/radix-platform/cert-manager-failure-2019-08-13-console-dev-radix-equinor-com.md)