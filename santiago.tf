
data "huaweicloud_vpn_gateway_availability_zones" "zone_stg" {
  region     = "la-south-2"
  flavor        = "professional1"
  attachment_type = "vpc"
}

resource "huaweicloud_vpc" "stg" {
  region     = "la-south-2"
  name     = "vpc-santiago"
  cidr     = "10.128.10.0/24"
}

resource "huaweicloud_vpc_subnet" "vpn_stg" {
  region     = "la-south-2"
  name       = "subnet-santiago"
  cidr       = "10.128.10.0/24"
  gateway_ip = "10.128.10.1"
  vpc_id     = huaweicloud_vpc.stg.id
}

resource "huaweicloud_vpn_gateway" "vpn_stg" {
  region     = "la-south-2"
  name             = "vpn-stg-gateway"
  vpc_id           = huaweicloud_vpc.stg.id
  local_subnets    = [huaweicloud_vpc_subnet.vpn_stg.cidr]
  connect_subnet   = huaweicloud_vpc_subnet.vpn_stg.id
  attachment_type  = "vpc"

  availability_zones = [
    data.huaweicloud_vpn_gateway_availability_zones.zone_stg.names[0],
    data.huaweicloud_vpn_gateway_availability_zones.zone_stg.names[1]
  ]

  eip1 {
    bandwidth_name = "eip-stg-vpn-1"
    type           = "5_bgp"
    bandwidth_size = 5
    charge_mode    = "traffic"
  }

  eip2 {
    bandwidth_name = "eip-stg-vpn-2"
    type           = "5_bgp"
    bandwidth_size = 5
    charge_mode    = "traffic"
  }
}

resource "huaweicloud_vpn_customer_gateway" "cgw_sp" {
  region     = "la-south-2"
  name     = "cgw_sp_stg"
  id_value = huaweicloud_vpn_gateway.vpn.eip1[0].ip_address
}

resource "huaweicloud_vpn_connection" "vpn_conn_stg" {
  region     = "la-south-2"
  name                = "vpn-stg-to-sp"
  gateway_id          = huaweicloud_vpn_gateway.vpn_stg.id
  gateway_ip          = huaweicloud_vpn_gateway.vpn_stg.eip1[0].id
  customer_gateway_id = huaweicloud_vpn_customer_gateway.cgw_sp.id
  peer_subnets = [
    huaweicloud_vpc_subnet.sp_net.cidr,
    huaweicloud_vpc_subnet.sp_app.cidr
  ]
  vpn_type = "static"
  psk      = var.vpn_psk

  ikepolicy {
    authentication_algorithm = "sha2-256"
    authentication_method    = "pre-share"
    encryption_algorithm     = "aes-128"
    ike_version              = "v2"
    lifetime_seconds         = 86400
    pfs                      = "group14"
  }

  ipsecpolicy {
    authentication_algorithm = "sha2-256"
    encapsulation_mode       = "tunnel"
    encryption_algorithm     = "aes-128"
    lifetime_seconds         = 3600
    pfs                      = "group14"
    transform_protocol       = "esp"
  }

  depends_on = [
    huaweicloud_vpn_customer_gateway.cgw_stg
  ]
}


resource "huaweicloud_networking_secgroup" "stg_main" {
  region = "la-south-2"
  name                 = "sg-main"
  delete_default_rules = true
}

resource "huaweicloud_networking_secgroup_rule" "stg_egress" {
  region = "la-south-2"
  security_group_id = huaweicloud_networking_secgroup.stg_main.id
  description       = "Allow all outbound traffic"
  direction         = "egress"
  ethertype         = "IPv4"
}

resource "huaweicloud_networking_secgroup_rule" "stg_ingress" {
  region = "la-south-2"
  security_group_id = huaweicloud_networking_secgroup.stg_main.id
  description       = "Allow VPC access"
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "10.0.0.0/8"
}


data "huaweicloud_images_image" "stg" {
  region = "la-south-2"
  name        = "Ubuntu 24.04 server 64bit"
  most_recent = true
}

resource "huaweicloud_compute_instance" "stg" {
  name                = "ecs-stg"
  image_id            = data.huaweicloud_images_image.stg.id
  flavor_id           = "t6.small.1"
  security_group_ids  = [
    huaweicloud_networking_secgroup.stg_main.id
  ]
  region              = "la-south-2"
  availability_zone   = "la-south-2a"
  admin_pass          = var.default_password
  system_disk_type    = "SAS"
  system_disk_size    = 10

  network {
    uuid              = huaweicloud_vpc_subnet.vpn_stg.id
    fixed_ip_v4       = "10.128.10.10"
  }
}