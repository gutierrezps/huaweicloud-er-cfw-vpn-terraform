resource "huaweicloud_cfw_firewall" "main" {
  name = "cfw-main"

  east_west_firewall_inspection_cidr = "10.255.30.0/24"
  east_west_firewall_er_id           = huaweicloud_er_instance.main.id
  east_west_firewall_mode            = "er"

  flavor {
    version = "Professional"
  }
}
