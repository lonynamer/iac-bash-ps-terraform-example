
variable "dns-creds" {
  type = "map"

  default = {
    set_dns_user = ""
    set_dns_password = ""
    set_dns_server = ""
  }
}


variable "dhcp-creds" {
  type = "map"

  default = {
    set_dhcp_user = ""
    set_dhcp_password = ""
    set_dhcp_server = ""
  }
}
