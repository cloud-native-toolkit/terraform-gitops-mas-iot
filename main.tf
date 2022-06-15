locals {
  name          = "ibm-masapp-iot"
  operator_name  = "ibm-masapp-iot-operator"
  bin_dir        = module.setup_clis.bin_dir
  tmp_dir        = "${path.cwd}/.tmp/${local.name}"
  yaml_dir       = "${local.tmp_dir}/chart/${local.name}"
  operator_yaml_dir = "${local.tmp_dir}/chart/${local.operator_name}"
  workspace_name    = "${var.instanceid}-${var.workspace_id}"

  layer              = "services"
  type               = "instances"
  operator_type      = "operators"
  application_branch = "main"
  appname            = "ibm-mas-${var.appid}"
  namespace          = "mas-${var.instanceid}-${var.appid}"
  layer_config       = var.gitops_config[local.layer]
  installPlan        = var.installPlan

# set values content for subscription
  values_content = {
        masapp = {
          name = local.appname
          appid = var.appid
          instanceid = var.instanceid
          namespace = local.namespace
          workspaceid = var.workspace_id
        }
        workspace = {
          name = local.workspace_name
        }
    }
  values_content_operator = {
        masapp = {
          name = local.appname
        }
        subscription = {
          channel = var.channel
          installPlanApproval = local.installPlan
          source = var.catalog
          sourceNamespace = var.catalog_namespace
        }
    }

}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

# create namespace for mas application
module masappNamespace {
  source = "github.com/cloud-native-toolkit/terraform-gitops-namespace.git"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  name = "${local.namespace}"
  create_operator_group = true
}

# add entitlement secret
module "pullsecret" {
  depends_on = [module.masappNamespace]

  source = "github.com/cloud-native-toolkit/terraform-gitops-pull-secret.git"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  server_name = var.server_name
  kubeseal_cert = var.kubeseal_cert
  
  namespace = module.masappNamespace.name
  docker_server = "cp.icr.io"
  docker_username = "cp"
  docker_password = var.entitlement_key
  secret_name = "ibm-entitlement"
}

## do we need jdbc config?? yes - set to system most likely but may do this in bom as optional


# Add values for operator chart
resource "null_resource" "deployAppValsOperator" {

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.operator_name}' '${local.operator_yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content_operator)
    }
  }
}


# Add values for instance charts
resource "null_resource" "deployAppVals" {

  triggers = {
    addons = join(",", var.addons)
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.name}' '${local.yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}


# Deploy Operator
resource gitops_module masapp_operator {
  depends_on = [null_resource.deployAppValsOperator, module.pullsecret]

  name        = local.operator_name
  namespace   = local.namespace
  content_dir = local.operator_yaml_dir
  server_name = var.server_name
  layer       = local.layer
  type        = local.operator_type
  branch      = local.application_branch
  config      = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}

# Deploy Instance
resource gitops_module masapp {
  depends_on = [gitops_module.masapp_operator]

  name        = local.name
  namespace   = local.namespace
  content_dir = local.yaml_dir
  server_name = var.server_name
  layer       = local.layer
  type        = local.type
  branch      = local.application_branch
  config      = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}


