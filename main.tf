resource "huaweicloud_vpc" "sp_net" {
  name = "vpc-networking"
  cidr = "10.255.10.0/24"
}

resource "huaweicloud_vpc_subnet" "sp_net" {
  name       = "subnet-networking"
  cidr       = huaweicloud_vpc.sp_net.cidr
  gateway_ip = "10.255.10.1"
  vpc_id     = huaweicloud_vpc.sp_net.id
}

resource "huaweicloud_vpc" "sp_app" {
  name = "vpc-application"
  cidr = "10.255.20.0/24"
}

resource "huaweicloud_vpc_subnet" "sp_app" {
  name       = "subnet-application"
  cidr       = huaweicloud_vpc.sp_app.cidr
  gateway_ip = "10.255.20.1"
  vpc_id     = huaweicloud_vpc.sp_app.id
}

resource "huaweicloud_networking_secgroup" "sp_main" {
  name                 = "sg-main"
  delete_default_rules = true
}

resource "huaweicloud_networking_secgroup_rule" "sp_egress" {
  security_group_id = huaweicloud_networking_secgroup.sp_main.id
  description       = "Allow all outbound traffic"
  direction         = "egress"
  ethertype         = "IPv4"
}

resource "huaweicloud_networking_secgroup_rule" "sp_ingress" {
  security_group_id = huaweicloud_networking_secgroup.sp_main.id
  description       = "Allow VPC access"
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "10.0.0.0/8"
}


########################################################################
# NAT Gateway for outbound internet access

# resource "huaweicloud_nat_gateway" "main" {
#   name      = "nat-seniorx"
#   spec      = "1"
#   vpc_id    = huaweicloud_vpc.main.id
#   subnet_id = huaweicloud_vpc_subnet.vpn.id
# }

# resource "huaweicloud_vpc_eip" "nat" {
#   name = "eip-nat-seniorx"
#   publicip {
#     type = "5_bgp"
#   }

#   bandwidth {
#     share_type  = "PER"
#     name        = "bandwidth-nat-seniorx"
#     size        = 300
#     charge_mode = "traffic"
#   }
# }

# resource "huaweicloud_nat_snat_rule" "main" {
#   nat_gateway_id = huaweicloud_nat_gateway.main.id
#   floating_ip_id = huaweicloud_vpc_eip.nat.id
#   source_type    = 1
#   cidr           = huaweicloud_vpc.main.cidr
# }