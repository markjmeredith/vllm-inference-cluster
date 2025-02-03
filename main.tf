##############################################################################
# Terraform Main IaC
##############################################################################

locals {
  # Constants
  opt_directory    = "/opt/ibm"
  part_label       = "inference"
  install_log_path = "/var/log/inference_cluster_install.log"
}

data "ibm_resource_group" "group" {
  name = var.resource_group_name
}

data "http" "pubip" {
  url = "http://ipv4.icanhazip.com"
}

data "ibm_is_image" "inference" {
  name = var.inference_node_base_image_name
}

module "vpc" {
  source            = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version           = "7.17.1"
  resource_group_id = data.ibm_resource_group.group.id
  region            = var.ibmcloud_region
  name              = var.prefix
  use_public_gateways = {
    zone-1 : length(var.subnets.zone-1) > 0 ? true : false,
    zone-2 : length(var.subnets.zone-2) > 0 ? true : false,
    zone-3 : length(var.subnets.zone-3) > 0 ? true : false
  }
  network_acls = [{
    name = "vpc-acl"
    rules = [
      {
        action      = "allow"
        destination = "0.0.0.0/0"
        direction   = "inbound"
        name        = "ingress"
        source      = "0.0.0.0/0"
      },
      {
        action      = "allow"
        destination = "0.0.0.0/0"
        direction   = "outbound"
        name        = "egress"
        source      = "0.0.0.0/0"
      }
    ]
  }]
  subnets = {
    zone-1 : [for o in var.subnets.zone-1 : merge(o, { acl_name : "vpc-acl", public_gateway : true })],
    zone-2 : [for o in var.subnets.zone-2 : merge(o, { acl_name : "vpc-acl", public_gateway : true })],
    zone-3 : [for o in var.subnets.zone-3 : merge(o, { acl_name : "vpc-acl", public_gateway : true })]
  }
}

resource "ibm_is_security_group" "nodes" {
  name           = format("%s-%s", var.prefix, "sg-nodes")
  vpc            = module.vpc.vpc_id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group" "load_balancer" {
  name           = format("%s-%s", var.prefix, "sg-lb")
  vpc            = module.vpc.vpc_id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group_rule" "in_ssh" {
  count     = var.inference_node_ssh_key_name == "" ? 0 : 1
  direction = "inbound"
  group     = ibm_is_security_group.nodes.id
  remote    = chomp(data.http.pubip.response_body)
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "in_uvicorn" {
  direction = "inbound"
  group     = ibm_is_security_group.nodes.id
  remote    = ibm_is_security_group.load_balancer.id
  tcp {
    port_min = 8000
    port_max = 8000
  }
}

resource "ibm_is_security_group_rule" "in_lb" {
  direction = "inbound"
  group     = ibm_is_security_group.load_balancer.id
  remote    = "0.0.0.0/0"
  tcp {
    port_min = var.load_balancer_port
    port_max = var.load_balancer_port
  }
}

resource "ibm_is_security_group_rule" "out_nodes" {
  direction = "outbound"
  group     = ibm_is_security_group.nodes.id
  remote    = "0.0.0.0/0"
}

resource "ibm_is_security_group_rule" "out_lb" {
  direction = "outbound"
  group     = ibm_is_security_group.load_balancer.id
  remote    = "0.0.0.0/0"
}

data "ibm_is_ssh_key" "inference" {
  count = var.inference_node_ssh_key_name == "" ? 0 : 1
  name  = var.inference_node_ssh_key_name
}

resource "ibm_iam_trusted_profile" "inference" {
  name = var.prefix
}

resource "ibm_iam_trusted_profile_policy" "cos" {
  count      = var.model_cos_bucket_name == "" ? 0 : 1
  profile_id = ibm_iam_trusted_profile.inference.id
  roles      = ["Reader"]
  resources {
    attributes = {
      "serviceName" = "cloud-object-storage"
    }
  }
}

resource "ibm_iam_trusted_profile_claim_rule" "inference" {
  profile_id = ibm_iam_trusted_profile.inference.id
  type       = "Profile-CR"
  conditions {
    claim    = "vpc_id"
    operator = "EQUALS"
    value    = format("\"%s\"", module.vpc.vpc_id)
  }
  cr_type = "VSI"
}

locals {
  inference_directory = format("%s/%s", local.opt_directory, "inference")
  setup_script = templatefile(format("%s/%s", path.module, "scripts/setup.sh.tpl"), {
    trusted_profile_id     = ibm_iam_trusted_profile.inference.id,
    inference_directory    = local.inference_directory,
    model_cos_bucket_name  = var.model_cos_bucket_name,
    model_huggingface_name = var.model_huggingface_name,
    region                 = var.ibmcloud_region
  })
  startup_script = templatefile(format("%s/%s", path.module, "scripts/startup.sh.tpl"), {
    model_or_path = var.model_cos_bucket_name == "" ? var.model_huggingface_name : "model.local"
  })
}

resource "ibm_is_instance_template" "inference" {
  name    = format("%s-%s", var.prefix, "vsi")
  image   = data.ibm_is_image.inference.id
  profile = var.inference_node_instance_profile
  primary_network_interface {
    subnet          = module.vpc.subnet_zone_list[0].id
    security_groups = [ibm_is_security_group.nodes.id]
  }
  vpc  = module.vpc.vpc_id
  zone = module.vpc.subnet_zone_list[0].zone
  keys = var.inference_node_ssh_key_name == "" ? [] : [data.ibm_is_ssh_key.inference[0].id]
  volume_attachments {
    delete_volume_on_instance_delete = true
    name                             = format("%s-%s", var.prefix, "data-attachment")
    volume_prototype {
      profile  = var.data_volume_profile
      capacity = var.data_volume_capacity
    }
  }
  metadata_service {
    enabled = true
  }
  user_data = format("%s\n%s", "#cloud-config", yamlencode({
    write_files = [
      {
        content     = yamlencode(var.vllm_serve_options)
        path        = format("%s/%s", "/tmp/inference", "config.yaml")
        permissions = "0644"
        owner       = "root"
      },
      {
        content     = file(format("%s/%s", path.module, "scripts/mkvol.sh"))
        path        = "/tmp/mkvol.sh"
        permissions = "0755"
        owner       = "root"
      },
      {
        content     = local.startup_script
        path        = format("%s/%s", "/tmp/inference", "startup.sh")
        permissions = "0755"
        owner       = "root"
      },
      {
        content     = local.setup_script
        path        = "/tmp/setup.sh"
        permissions = "0755"
        owner       = "root"
      }
    ],
    runcmd = [
      format("/tmp/mkvol.sh \"%s\" \"%s\"", local.opt_directory, local.part_label),
      format("/tmp/setup.sh > \"%s\" 2>&1", local.install_log_path)
    ]
  }))
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_lb" "inference" {
  name            = format("%s-%s", var.prefix, "lb")
  subnets         = module.vpc.subnet_zone_list[*].id
  resource_group  = data.ibm_resource_group.group.id
  security_groups = [ibm_is_security_group.load_balancer.id]
  type            = var.load_balancer_type
}

resource "ibm_is_lb_pool" "inference" {
  algorithm           = "round_robin"
  health_delay        = 20
  health_retries      = 2
  health_timeout      = 10
  health_type         = "http"
  health_monitor_port = 8000
  health_monitor_url  = "/health"
  lb                  = ibm_is_lb.inference.id
  name                = format("%s-%s", var.prefix, "lb-pool")
  protocol            = "http"
}

resource "ibm_is_lb_listener" "inference" {
  lb           = ibm_is_lb.inference.id
  port         = var.load_balancer_port
  protocol     = "http"
  default_pool = ibm_is_lb_pool.inference.id
}

resource "ibm_is_instance_group" "inference" {
  instance_template  = ibm_is_instance_template.inference.id
  name               = format("%s-%s", var.prefix, "vsi-ig")
  subnets            = module.vpc.subnet_zone_list[*].id
  instance_count     = var.inference_node_count
  application_port   = 8000
  load_balancer      = ibm_is_lb.inference.id
  load_balancer_pool = ibm_is_lb_pool.inference.pool_id
  resource_group     = data.ibm_resource_group.group.id
}
