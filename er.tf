resource "huaweicloud_er_instance" "main" {
  availability_zones = ["sa-brazil-1a", "sa-brazil-1b"]

  name = "er-sp"
  asn  = 65000
}

resource "huaweicloud_er_vpc_attachment" "sp_net" {
  instance_id = huaweicloud_er_instance.main.id
  vpc_id      = huaweicloud_vpc.sp_net.id
  subnet_id   = huaweicloud_vpc_subnet.sp_net.id

  name                   = "sp_net"
  auto_create_vpc_routes = true
}

resource "huaweicloud_er_vpc_attachment" "sp_app" {
  instance_id = huaweicloud_er_instance.main.id
  vpc_id      = huaweicloud_vpc.sp_app.id
  subnet_id   = huaweicloud_vpc_subnet.sp_app.id

  name                   = "sp_app"
  auto_create_vpc_routes = true
}

resource "huaweicloud_er_route_table" "default" {
  instance_id = huaweicloud_er_instance.main.id
  name        = "rtb-default"
}

resource "huaweicloud_er_association" "default_sp_app" {
  instance_id    = huaweicloud_er_instance.main.id
  route_table_id = huaweicloud_er_route_table.default.id
  attachment_id  = huaweicloud_er_vpc_attachment.sp_app.id
}

resource "huaweicloud_er_association" "default_sp_net" {
  instance_id    = huaweicloud_er_instance.main.id
  route_table_id = huaweicloud_er_route_table.default.id
  attachment_id  = huaweicloud_er_vpc_attachment.sp_net.id
}


data "huaweicloud_er_attachments" "vpn" {
  instance_id    = huaweicloud_er_instance.main.id

  type = "vpn"
}

resource "huaweicloud_er_association" "default_vpn" {
  instance_id    = huaweicloud_er_instance.main.id
  route_table_id = huaweicloud_er_route_table.default.id
  attachment_id  = data.huaweicloud_er_attachments.vpn.attachments[0].id
}


resource "huaweicloud_er_static_route" "app" {
  route_table_id = huaweicloud_er_route_table.default.id
  destination    = huaweicloud_vpc.sp_app.cidr
  attachment_id  = huaweicloud_er_vpc_attachment.sp_app.id
}

resource "huaweicloud_er_static_route" "net" {
  route_table_id = huaweicloud_er_route_table.default.id
  destination    = huaweicloud_vpc.sp_net.cidr
  attachment_id  = huaweicloud_er_vpc_attachment.sp_net.id
}

resource "huaweicloud_er_propagation" "default_vpn" {
  instance_id    = huaweicloud_er_instance.main.id
  route_table_id = huaweicloud_er_route_table.default.id
  attachment_id  = data.huaweicloud_er_attachments.vpn.attachments[0].id
}
