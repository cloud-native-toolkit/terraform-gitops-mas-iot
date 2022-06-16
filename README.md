#  Maximo Application Suite - MAS IoT Application Gitops terraform module

Deploys MAS IoT applications as part of Maximo Application Suite via gitops.  To run, download the BOM (Bill of Materials) from the module catalog and build the terraform from there.  Specify the MAS-Core instance id - in the `instanceid` variable.  This will create a namespace of the name `mas-(instanceid)-iot`.

Note if your cluster is not setup for gitops, download the gitops bootstrap BOM from the module catalog first to setup the gitops tooling.

## Database Setup
This IoT app normally uses the system database scope for db2wh.  DB2Warehouse as part of CP4D can be used for the module, or you can use any of the supported databases.

## Kafka Setup
Kafka is also required for this module set to a scope of system.  You can set this up prior to iot installation and configure on your own, or you can use the mas strimzi module found here:
https://github.com/cloud-native-toolkit/terraform-gitops-mas-kafka

## Supported platforms

- OCP 4.8+

## Suggested companion modules

The module itself requires some information from the cluster and needs a
namespace to be created. The following companion
modules can help provide the required information:

- Gitops:  github.com/cloud-native-toolkit/terraform-tools-gitops
- Gitops Bootstrap: github.com/cloud-native-toolkit/terraform-util-gitops-bootstrap
- Pull Secret:  github.com/cloud-native-toolkit/terraform-gitops-pull-secret
- Catalog: github.com/cloud-native-toolkit/terraform-gitops-cp-catalogs 
- Cert:  github.com/cloud-native-toolkit/terraform-util-sealed-secret-cert
- Cluster: github.com/cloud-native-toolkit/terraform-ocp-login
- CertManager: github.com/cloud-native-toolkit/terraform-gitops-ocp-cert-manager
- Strimzi: github.com/cloud-native-toolkit/terraform-gitops-kafka-strimzi
- Kafka: github.com/cloud-native-toolkit/terraform-gitops-mas-kafka
- JDBC: github.com/cloud-native-toolkit/terraform-gitops-mas-jdbc

## Example usage

```hcl-terraform
module "mas_iot" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-mas-iot"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  kubeseal_cert = module.gitops.sealed_secrets_cert

  instanceid = module.mas_kafka.instanceid
  workspace_id = "demo"
  entitlement_key = module.cp_catalogs.entitlement_key
  jdbc_scope = module.masjdbc.scope
 
}
```
