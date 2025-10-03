data "huaweicloud_images_image" "sp" {
  name        = "Ubuntu 24.04 server 64bit"
  most_recent = true
}

resource "huaweicloud_compute_instance" "sp" {
  name                = "ecs-sp"
  image_id            = data.huaweicloud_images_image.sp.id
  flavor_id           = "t6.small.1"
  security_group_ids  = [
    huaweicloud_networking_secgroup.sp_main.id
  ]
  region              = "sa-brazil-1"
  availability_zone   = "sa-brazil-1a"
  admin_pass          = var.default_password
  system_disk_type    = "SAS"
  system_disk_size    = 10

  network {
    uuid              = huaweicloud_vpc_subnet.sp_app.id
    fixed_ip_v4       = "10.255.20.10"
  }
}


resource "huaweicloud_compute_instance" "sp_net" {
  name                = "ecs-sp-net"
  image_id            = data.huaweicloud_images_image.sp.id
  flavor_id           = "t6.small.1"
  security_group_ids  = [
    huaweicloud_networking_secgroup.sp_main.id
  ]
  region              = "sa-brazil-1"
  availability_zone   = "sa-brazil-1a"
  admin_pass          = var.default_password
  system_disk_type    = "SAS"
  system_disk_size    = 10

  network {
    uuid              = huaweicloud_vpc_subnet.sp_net.id
    fixed_ip_v4       = "10.255.10.10"
  }
}
