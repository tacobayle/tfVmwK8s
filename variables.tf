#
# variables
#
variable "vsphere_username" {}
variable "vsphere_password" {}
variable "ubuntu_password" {
  default = null
}
variable "vsphere_server" {
  default = "wdc-06-vc12.oc.vmware.com"
}
variable "vcenter_dc" {
  default = "wdc-06-vc12"
}

variable "vcenter_cluster" {
  default = "wdc-06-vc12c01"
}

variable "vcenter_datastore" {
  default = "wdc-06-vc12c01-vsan"
}

variable "vcenter_network" {
  default = "vxw-dvs-34-virtualwire-3-sid-6120002-wdc-06-vc12-avi-mgmt"
}

variable "worker_count" {
  default = "3"
}

variable "nodes_ip4_addresses" {
  default = "10.206.112.70, 10.206.112.71, 10.206.112.72, 10.206.112.73, 10.206.112.74, 10.206.112.75"
}

variable "network_prefix" {
  default = "22"
}

variable "gateway4" {
  default = "10.206.112.1"
}

variable "nameservers" {
//  default = "10.206.8.130, 10.206.8.130, 10.206.8.131"
  default = "8.8.8.8"
}

variable "K8s_version" {
  default = "1.21.3-00" # k8s version
}

variable "K8s_network_pod" {
  default = "192.168.0.0/16"
}

variable "K8s_cni_url" {
  default = "https://github.com/vmware-tanzu/antrea/releases/download/v1.2.3/antrea.yml"
}

variable "Docker_version" {
  default = "5:20.10.7~3-0~ubuntu-focal"
}

variable "docker_compose_version" {
  default = "1.29.2"
}

variable "harbor_url" {
  default = "https://github.com/goharbor/harbor/releases/download/v2.4.1/harbor-online-installer-v2.4.1.tgz"
}

variable "ssh_key" {
  type = map
  default = {
    algorithm            = "RSA"
    rsa_bits             = "4096"
    private_key_name = "ssh_private_key_tf_ubuntu"
    file_permission      = "0600"
  }
}

variable "dhcp" {
  default = true
}

variable "content_library" {
  default = {
    basename = "content_library_tf_"
    source_url = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.ova"
  }
}

variable "master" {
  type = map
  default = {
    basename = "master-tf-"
    username = "ubuntu"
    cpu = 2
    if_name = "ens192"
    memory = 8192
    disk = 20
    wait_for_guest_net_routable = "false"
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
  }
}

variable "worker" {
  type = map
  default = {
    basename = "worker-tf-"
    username = "ubuntu"
    cpu = 4
    if_name = "ens192"
    memory = 16384
    disk = 20
    wait_for_guest_net_routable = "false"
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
  }
}

//variable "harbor" {
//  type = map
//  default = {
//    basename = "harbor-tf-"
//    username = "ubuntu"
//    cpu = 2
//    if_name = "ens192"
//    memory = 4096
//    disk = 128
//    wait_for_guest_net_routable = "false"
//    netplanFile = "/etc/netplan/50-cloud-init.yaml"
//  }
//}

//variable "nfs" {
//  type = map
//  default = {
//    basename = "nfs-tf-"
//    username = "ubuntu"
//    cpu = 2
//    if_name = "ens192"
//    memory = 4096
//    disk = 128
//    wait_for_guest_net_routable = "false"
//    netplanFile = "/etc/netplan/50-cloud-init.yaml"
//  }
//}