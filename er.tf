resource "huaweicloud_er_instance" "main" {
  availability_zones = ["sa-brazil-1a", "sa-brazil-1b"]

  name = "er-sp"
  asn  = 65000
}

locals {
  er_id = huaweicloud_er_instance.main.id
}

# ----------------------------------------------------------------------------
# VPC Attachments
# (VPN and CFW attachments are created automatically)

resource "huaweicloud_er_vpc_attachment" "sp_net" {
  instance_id = local.er_id
  vpc_id      = huaweicloud_vpc.sp_net.id
  subnet_id   = huaweicloud_vpc_subnet.sp_net.id

  name                   = "sp_net"
  auto_create_vpc_routes = true
}

resource "huaweicloud_er_vpc_attachment" "sp_app" {
  instance_id = local.er_id
  vpc_id      = huaweicloud_vpc.sp_app.id
  subnet_id   = huaweicloud_vpc_subnet.sp_app.id

  name                   = "sp_app"
  auto_create_vpc_routes = true
}

resource "huaweicloud_er_vpc_attachment" "sp_dmz" {
  instance_id = local.er_id
  vpc_id      = huaweicloud_vpc.sp_dmz.id
  subnet_id   = huaweicloud_vpc_subnet.sp_dmz.id

  name                   = "sp_dmz"
  auto_create_vpc_routes = true
}

data "huaweicloud_er_attachments" "vpn" {
  instance_id = local.er_id
  type        = "vpn"
}

data "huaweicloud_er_attachments" "cfw" {
  instance_id = local.er_id
  type        = "cfw"
}

locals {
  er_attach_app = huaweicloud_er_vpc_attachment.sp_app.id
  er_attach_net = huaweicloud_er_vpc_attachment.sp_net.id
  er_attach_dmz = huaweicloud_er_vpc_attachment.sp_dmz.id
  er_attach_cfw = length(data.huaweicloud_er_attachments.cfw.attachments) > 0 ? one(data.huaweicloud_er_attachments.cfw.attachments).id : null
  er_attach_vpn = length(data.huaweicloud_er_attachments.vpn.attachments) > 0 ? one(data.huaweicloud_er_attachments.vpn.attachments).id : null
}

# ----------------------------------------------------------------------------
# Route Table for VPCs

resource "huaweicloud_er_route_table" "vpcs" {
  instance_id = local.er_id
  name        = "rtb-vpcs"
}

locals {
  er_rtb_vpcs = huaweicloud_er_route_table.vpcs.id
}

resource "huaweicloud_er_association" "vpcs_sp_app" {
  instance_id    = local.er_id
  route_table_id = local.er_rtb_vpcs
  attachment_id  = local.er_attach_app
}

resource "huaweicloud_er_association" "vpcs_sp_dmz" {
  instance_id    = local.er_id
  route_table_id = local.er_rtb_vpcs
  attachment_id  = local.er_attach_dmz
}

resource "huaweicloud_er_association" "vpcs_sp_net" {
  instance_id    = local.er_id
  route_table_id = local.er_rtb_vpcs
  attachment_id  = local.er_attach_net
}

resource "huaweicloud_er_static_route" "vpcs_cfw" {
  count          = local.er_attach_cfw != null ? 1 : 0
  route_table_id = local.er_rtb_vpcs
  destination    = "0.0.0.0/0"
  attachment_id  = local.er_attach_cfw
}

# ----------------------------------------------------------------------------
# Route Table for VPN

resource "huaweicloud_er_route_table" "vpn" {
  instance_id = local.er_id
  name        = "rtb-vpn"
}

locals {
  er_rtb_vpn = huaweicloud_er_route_table.vpn.id
}

resource "huaweicloud_er_association" "vpn_vpn" {
  count          = local.er_attach_vpn != null ? 1 : 0
  instance_id    = local.er_id
  route_table_id = local.er_rtb_vpn
  attachment_id  = local.er_attach_vpn
}

resource "huaweicloud_er_static_route" "app" {
  count          = local.er_attach_cfw != null ? 1 : 0
  route_table_id = local.er_rtb_vpn
  destination    = huaweicloud_vpc.sp_app.cidr
  attachment_id  = local.er_attach_cfw
}

resource "huaweicloud_er_static_route" "net" {
  count          = local.er_attach_cfw != null ? 1 : 0
  route_table_id = local.er_rtb_vpn
  destination    = huaweicloud_vpc.sp_net.cidr
  attachment_id  = local.er_attach_cfw
}

# ----------------------------------------------------------------------------
# Route Table for CFW

resource "huaweicloud_er_route_table" "cfw" {
  instance_id = local.er_id
  name        = "rtb-cfw"
}

locals {
  er_rtb_cfw = huaweicloud_er_route_table.cfw.id
}

resource "huaweicloud_er_association" "cfw_cfw" {
  count          = local.er_attach_cfw != null ? 1 : 0
  instance_id    = local.er_id
  route_table_id = local.er_rtb_cfw
  attachment_id  = local.er_attach_cfw
}

resource "huaweicloud_er_propagation" "cfw_app" {
  instance_id    = local.er_id
  route_table_id = local.er_rtb_cfw
  attachment_id  = local.er_attach_app
}

resource "huaweicloud_er_propagation" "cfw_net" {
  instance_id    = local.er_id
  route_table_id = local.er_rtb_cfw
  attachment_id  = local.er_attach_net
}

resource "huaweicloud_er_propagation" "cfw_dmz" {
  instance_id    = local.er_id
  route_table_id = local.er_rtb_cfw
  attachment_id  = local.er_attach_dmz
}

resource "huaweicloud_er_propagation" "cfw_vpn" {
  count          = local.er_attach_vpn != null ? 1 : 0
  instance_id    = local.er_id
  route_table_id = local.er_rtb_cfw
  attachment_id  = local.er_attach_vpn
}

resource "huaweicloud_er_static_route" "cfw_internet" {
  route_table_id = local.er_rtb_cfw
  destination    = "0.0.0.0/0"
  attachment_id  = local.er_attach_dmz
}
