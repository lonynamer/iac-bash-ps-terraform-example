
data "vsphere_network" "d-l-0" {
name = "d-l-0-3006-data-local-10.140.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "d-l-1" {
name = "d-l-1-3007-data-local-10.141.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "d-l-2" {
name = "d-l-2-3008-data-local-10.142.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "d-r-0" {
name = "d-r-0-3015-data-remote-10.143.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "d-r-1" {
name = "d-r-1-3016-data-remote-10.144.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "d-r-2" {
name = "d-r-2-3017-data-remote-10.145.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "m-l-0" {
name = "m-l-0-3003-management-local-10.130.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "m-l-1" {
name = "m-l-1-3004-management-local-10.131.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "m-l-2" {
name = "m-l-2-3005-management-local-10.132.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "m-r-0" {
name = "m-r-0-3012-management-remote-10.133.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "m-r-1" {
name = "m-r-1-3013-management-remote-10.134.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "m-r-2" {
name = "m-r-2-3014-management-remote-10.135.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "o-l-0" {
name = "o-l-0-3000-oracle-pri-local-10.120.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "o-l-1" {
name = "o-l-1-3001-oracle-pri-local-10.121.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "o-l-2" {
name = "o-l-2-3002-oracle-pri-local-10.122.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "o-r-0" {
name = "o-r-0-3009-oracle-pri-remote-10.123.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "o-r-1" {
name = "o-r-1-3010-oracle-pri-remote-10.124.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "o-r-2" {
name = "o-r-2-3011-oracle-pri-remote-10.125.0-3.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "pd-l-0" {
name = "pd-l-0-2998-pdata-local-10.140.20-23.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "pd-l-1" {
name = "pd-l-1-2998-pdata-local-10.140.40-43.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "pd-r-0" {
name = "pd-r-0-2998-pdata-remote-10.141.20-23.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "pd-r-1" {
name = "pd-r-1-2998-pdata-remote-10.141.40-43.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "pm-l-0" {
name = "pm-l-0-2999-pmanagement-local-10.130.20-23.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "pm-l-1" {
name = "pm-l-1-2999-pmanagement-local-10.130.40-43.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "pm-r-0" {
name = "pm-r-0-2999-pmanagement-remote-10.131.20-23.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "pm-r-1" {
name = "pm-r-1-2999-pmanagement-remote-10.131.40-43.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "po-l-0" {
name = "po-l-0-2999-poracle-pri-local-10.120.20-23.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "po-l-1" {
name = "po-l-1-2999-porale-pri-local-10.120.40-43.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "po-r-0" {
name = "po-r-0-2999-poracle-pri-remote-10.121.20-23.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "po-r-1" {
name = "po-r-1-2999-poracle-pri-remote-10.121.40-43.254-22"
datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
