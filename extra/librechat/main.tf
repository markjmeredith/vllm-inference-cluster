data "ibm_is_vpc" "existing" {
  name = var.vpc_name
}

data "http" "pubip" {
  url = "http://ipv4.icanhazip.com"
}

data "ibm_is_image" "libre" {
  name = var.base_image_name
}

resource "ibm_is_vpc_address_prefix" "libre" {
  name = format("%s-%s", var.prefix, "prefix")
  cidr = var.subnet_cidr
  vpc  = data.ibm_is_vpc.existing.id
  zone = format("%s-1", var.ibmcloud_region)
}

resource "ibm_is_subnet" "libre" {
  depends_on      = [ibm_is_vpc_address_prefix.libre]
  name            = format("%s-%s", var.prefix, "subnet")
  zone            = format("%s-1", var.ibmcloud_region)
  vpc             = data.ibm_is_vpc.existing.id
  resource_group  = data.ibm_is_vpc.existing.resource_group
  ipv4_cidr_block = var.subnet_cidr
}

data "ibm_is_ssh_key" "inference" {
  count = var.ssh_key_name == "" ? 0 : 1
  name  = var.ssh_key_name
}

resource "ibm_is_security_group" "libre" {
  name           = format("%s-%s", var.prefix, "sg-libre")
  vpc            = data.ibm_is_vpc.existing.id
  resource_group = data.ibm_is_vpc.existing.resource_group
}

resource "ibm_is_security_group_rule" "in_ssh" {
  count     = var.ssh_key_name == "" ? 0 : 1
  direction = "inbound"
  group     = ibm_is_security_group.libre.id
  remote    = chomp(data.http.pubip.response_body)
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "in_chat" {
  direction = "inbound"
  group     = ibm_is_security_group.libre.id
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 3080
    port_max = 3080
  }
}

resource "ibm_is_security_group_rule" "out" {
  direction = "outbound"
  group     = ibm_is_security_group.libre.id
  remote    = "0.0.0.0/0"
}

locals {
  librechat_config = templatefile(format("%s/%s", path.module, "config/librechat.yaml.tpl"), {
    openai_endpoint_name          = var.openai_endpoint_name,
    openai_endpoint_base_url      = var.openai_endpoint_base_url,
    openai_endpoint_default_model = var.openai_endpoint_default_model,
    openai_endpoint_display_name  = var.openai_endpoint_display_name
  })
}

resource "ibm_is_instance" "libre" {
  name    = format("%s-%s", var.prefix, "vsi")
  image   = data.ibm_is_image.libre.id
  profile = var.instance_profile
  primary_network_interface {
    subnet          = ibm_is_subnet.libre.id
    security_groups = [ibm_is_security_group.libre.id]
  }
  vpc  = data.ibm_is_vpc.existing.id
  zone = format("%s-1", var.ibmcloud_region)
  keys = var.ssh_key_name == "" ? [] : [data.ibm_is_ssh_key.inference[0].id]
  user_data = format("%s\n%s", "#cloud-config", yamlencode({
    write_files = [
      {
        content     = local.librechat_config
        path        = format("%s/%s", "/tmp/librechat", "librechat.yaml")
        permissions = "0644"
        owner       = "root"
      },
      {
        content     = file(format("%s/%s", path.module, "config/docker-compose.override.yml"))
        path        = format("%s/%s", "/tmp/librechat", "docker-compose.override.yml")
        permissions = "0644"
        owner       = "root"
      },
      {
        content     = file(format("%s/%s", path.module, "scripts/setup.sh"))
        path        = "/tmp/setup.sh"
        permissions = "0755"
        owner       = "root"
      },
    ],
    runcmd = [
      "/tmp/setup.sh >/var/log/librechat_setup.log 2>&1"
    ]
  }))
  resource_group = data.ibm_is_vpc.existing.resource_group
}

resource "ibm_is_floating_ip" "libre" {
  name           = format("%s-%s", var.prefix, "fip")
  resource_group = data.ibm_is_vpc.existing.resource_group
  target         = ibm_is_instance.libre.primary_network_interface[0].id
}
