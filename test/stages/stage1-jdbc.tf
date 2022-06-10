module "masjdbc" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-mas-jdbc"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  kubeseal_cert = module.gitops.sealed_secrets_cert

  instanceid = "masdemo"
  workspace_id = "demo"
  scope = "system"
  appid = "iot"

  db_user = var.database_username
  db_password = var.database_password
  db_cert = var.database_cert
  db_url = var.database_url 

}