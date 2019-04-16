# GET DATA
data "vsphere_datacenter" "dc" {
  name = "AXXANA-TLV-1"
}

data "vsphere_compute_cluster" "cl" {
  name          = "rnd-cluster-1"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pl" {
  name          = "rnd-resource-1"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_datastore_cluster" "ds" {
  name          = "rnd-datascluster-1"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "images" {
  count = "${length(keys(var.images))}"
  name          = "${var.images[count.index]}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

