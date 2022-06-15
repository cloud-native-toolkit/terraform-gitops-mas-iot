module "mas_kafka" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-mas-kafka"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  namespace = module.gitops_namespace.name
  kubeseal_cert = module.gitops.sealed_secrets_cert

  instanceid = "masdemo"
  storageclass = "ibmc-vpc-block-10iops-tier"
  
}