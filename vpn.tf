data "huaweicloud_vpn_gateway_availability_zones" "zone" {
  flavor          = "professional1"
  attachment_type = "er"
}

resource "huaweicloud_vpn_gateway" "vpn" {
  name             = "vpn-gateway-sp"
  access_subnet_id = huaweicloud_vpc_subnet.sp_net.id
  access_vpc_id    = huaweicloud_vpc.sp_net.id
  attachment_type  = "er"
  er_id            = huaweicloud_er_instance.main.id

  availability_zones = [
    data.huaweicloud_vpn_gateway_availability_zones.zone.names[0],
    data.huaweicloud_vpn_gateway_availability_zones.zone.names[1]
  ]

  eip1 {
    bandwidth_name = "eip-vpn-1"
    type           = "5_bgp"
    bandwidth_size = 5
    charge_mode    = "traffic"
  }

  eip2 {
    bandwidth_name = "eip-vpn-2"
    type           = "5_bgp"
    bandwidth_size = 5
    charge_mode    = "traffic"
  }
}

resource "huaweicloud_vpn_customer_gateway" "cgw_stg" {
  name     = "cgw-stg-sp"
  id_value = huaweicloud_vpn_gateway.vpn_stg.eip1[0].ip_address
}

resource "huaweicloud_vpn_connection" "vpn_conn_sp" {
  name                = "vpn-sp-to-stg"
  gateway_id          = huaweicloud_vpn_gateway.vpn.id
  gateway_ip          = huaweicloud_vpn_gateway.vpn.eip1[0].id
  customer_gateway_id = huaweicloud_vpn_customer_gateway.cgw_stg.id
  peer_subnets        = [huaweicloud_vpc_subnet.vpn_stg.cidr]
  vpn_type            = "static"
  psk                 = var.vpn_psk

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
    huaweicloud_vpn_customer_gateway.cgw_sp
  ]
}