provider "vsphere" {
  user           = ""
  password       = ""
  vsphere_server = ""

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

variable "provider-vsphere" {
  type           = "map"
  default = {
  user           = ""
  password       = ""
  vsphere_server = ""
  }
}
