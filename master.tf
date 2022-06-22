data "template_file" "network_master" {
  count            = (var.dhcp == false ? 1 : 0)
  template = file("templates/network.template")
  vars = {
    if_name = var.master.if_name
    ip4 = split(",", replace(var.nodes_ip4_addresses, " ", ""))[count.index]
    network_prefix = var.network_prefix
    gw4 = var.gateway4
    dns = var.nameservers
  }
}

data "template_file" "master_userdata_static" {
  template = file("${path.module}/userdata/master_static.userdata")
  count            = (var.dhcp == false ? 1 : 0)
  vars = {
    password      = var.ubuntu_password == null ? random_string.ubuntu_password.result : var.ubuntu_password
    pubkey        = chomp(tls_private_key.ssh.public_key_openssh)
    netplanFile = var.master.netplanFile
    hostname = "${var.master.basename}${random_string.id.result}"
    network_config  = base64encode(data.template_file.network_master[count.index].rendered)
    K8s_version = var.K8s_version
    Docker_version = var.Docker_version
    K8s_network_pod = var.K8s_network_pod
//    K8s_cni_url = var.K8s_cni_url
  }
}

data "template_file" "master_userdata_dhcp" {
  template = file("${path.module}/userdata/master_dhcp.userdata")
  count            = (var.dhcp == true ? 1 : 0)
  vars = {
    password      = var.ubuntu_password == null ? random_string.ubuntu_password.result : var.ubuntu_password
    pubkey        = chomp(tls_private_key.ssh.public_key_openssh)
    hostname = "${var.master.basename}${random_string.id.result}"
    K8s_version = var.K8s_version
    Docker_version = var.Docker_version
    if_name = var.master.if_name
    K8s_network_pod = var.K8s_network_pod
//    K8s_cni_url = var.K8s_cni_url
  }
}

resource "vsphere_virtual_machine" "master" {
  count            = 1
  name             = "${var.master.basename}${random_string.id.result}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path
  network_interface {
    network_id = data.vsphere_network.network.id
  }

  num_cpus = var.master.cpu
  memory = var.master.memory
  wait_for_guest_net_routable = var.master.wait_for_guest_net_routable
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.master.disk
    label            = "${var.master.basename}.lab_vmdk"
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = vsphere_content_library_item.file.id
  }

  vapp {
    properties = {
      hostname    = "${var.master.basename}${random_string.id.result}"
      public-keys = chomp(tls_private_key.ssh.public_key_openssh)
      user-data   = var.dhcp == true ? base64encode(data.template_file.master_userdata_dhcp[0].rendered) : base64encode(data.template_file.master_userdata_static[count.index].rendered)
    }
  }

  connection {
    host        = var.dhcp == true ? self.default_ip_address : split(",", replace(var.nodes_ip4_addresses, " ", ""))[count.index]
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }
}

resource "null_resource" "join_command" {
  count = (var.dhcp == true ? 1 : 0)
  depends_on = [vsphere_virtual_machine.master]
  provisioner "local-exec" {
    command = var.dhcp == true ? "scp -i ~/.ssh/${var.ssh_key.private_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${vsphere_virtual_machine.master[0].default_ip_address}:/home/ubuntu/join-command join-command" : "scp -i ~/.ssh/${var.ssh_key.private_key_name}.pem -o StrictHostKeyChecking=no ubuntu@${split(",", replace(var.nodes_ip4_addresses, " ", ""))[count.index]}:/home/ubuntu/join-command join-command"
  }
}

data "template_file" "K8s_sanity_check" {
  template = file("templates/K8s_check.sh.template")
  vars = {
    nodes = var.worker_count + 1
  }
}

resource "null_resource" "K8s_sanity_check" {
  depends_on = [null_resource.join_cluster]

  connection {
    host = var.dhcp == true ? vsphere_virtual_machine.master[0].default_ip_address : split(",", replace(var.nodes_ip4_addresses, " ", ""))[0]
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "local-exec" {
    command = "cat > K8s_sanity_check.sh <<EOL\n${data.template_file.K8s_sanity_check.rendered}\nEOL"
  }

  provisioner "file" {
    source = "K8s_sanity_check.sh"
    destination = "K8s_sanity_check.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash K8s_sanity_check.sh",
    ]
  }
}