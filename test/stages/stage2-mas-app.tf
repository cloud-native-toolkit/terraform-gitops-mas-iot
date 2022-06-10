module "gitops_module" {
  depends_on = [module.masjdbc]
  
  source = "./module"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  kubeseal_cert = module.gitops.sealed_secrets_cert

  instanceid = "masdemo"
  workspace_id = "demo"
  entitlement_key = module.cp_catalogs.entitlement_key
  jdbc_scope = module.masjdbc.scope
 
}

resource null_resource write_namespace {
  depends_on = [module.gitops_module]

  provisioner "local-exec" {
    command = "echo -n '${module.gitops_module.namespace}' > .namespace"
  }
}