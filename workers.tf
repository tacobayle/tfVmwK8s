data "template_file" "network_workers" {
  count            = var.dhcp == false ? var.worker_count : 0
  template = file("templates/network.template")
  vars = {
    if_name = var.worker.if_name
    ip4 = split(",", replace(var.nodes_ip4_addresses, " ", ""))[count.index + 3]
    network_prefix = var.network_prefix
    gw4 = var.gateway4
    dns = var.nameservers
  }
}

data "template_file" "workers_userdata_static" {
  template = file("${path.module}/userdata/worker_static.userdata")
  count            = var.dhcp == false ? var.worker_count : 0
  vars = {
    password      = var.ubuntu_password == null ? random_string.ubuntu_password.result : var.ubuntu_password
    pubkey        = chomp(tls_private_key.ssh.public_key_openssh)
    netplanFile = var.worker.netplanFile
    hostname = "${var.worker.basename}${count.index}-${random_string.id.result}"
    network_config  = base64encode(data.template_file.network_workers[count.index].rendered)
    K8s_version = var.K8s_version
    Docker_version = var.Docker_version
  }
}

data "template_file" "workers_userdata_dhcp" {
  template = file("${path.module}/userdata/worker_dhcp.userdata")
  count            = var.dhcp == true ? var.worker_count : 0
  vars = {
    password      = var.ubuntu_password == null ? random_string.ubuntu_password.result : var.ubuntu_password
    pubkey        = chomp(tls_private_key.ssh.public_key_openssh)
    hostname = "${var.worker.basename}${count.index}-${random_string.id.result}"
    K8s_version = var.K8s_version
    Docker_version = var.Docker_version
  }
}

resource "vsphere_virtual_machine" "workers" {
  count            = var.worker_count
  name             = "${var.worker.basename}${count.index}-${random_string.id.result}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  network_interface {
    network_id = data.vsphere_network.network.id
  }

  num_cpus = var.worker.cpu
  memory = var.worker.memory
  wait_for_guest_net_routable = var.worker.wait_for_guest_net_routable
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.worker.disk
    label            = "${var.worker.basename}.lab_vmdk"
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
      hostname    = "${var.worker.basename}${count.index}-${random_string.id.result}"
      public-keys = chomp(tls_private_key.ssh.public_key_openssh)
      user-data   = var.dhcp == true ? base64encode(data.template_file.workers_userdata_dhcp[count.index].rendered) : base64encode(data.template_file.workers_userdata_static[count.index].rendered)
    }
  }

  connection {
    host        = var.dhcp == true ? self.default_ip_address : split(",", replace(var.nodes_ip4_addresses, " ", ""))[count.index + 3]
    type        = "ssh"
    agent       = false
    user        = var.worker.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }
}

resource "null_resource" "copy_join_command_to_workers" {
  count            = var.worker_count
  depends_on = [null_resource.join_command, vsphere_virtual_machine.workers]
  provisioner "local-exec" {
    command = var.dhcp == true ? "scp -i ~/.ssh/${var.ssh_key.private_key_name}.pem -o StrictHostKeyChecking=no join-command ubuntu@${vsphere_virtual_machine.workers[count.index].default_ip_address}:/home/ubuntu/join-command" : "scp -i ~/.ssh/${var.ssh_key.private_key_name}.pem -o StrictHostKeyChecking=no join-command ubuntu@${split(",", replace(var.nodes_ip4_addresses, " ", ""))[count.index + 3]}:/home/ubuntu/join-command"
  }
}

resource "null_resource" "join_cluster" {
  count            = var.worker_count
  depends_on = [null_resource.copy_join_command_to_workers]

  connection {
    host        = var.dhcp == true ? vsphere_virtual_machine.workers[count.index].default_ip_address : split(",", replace(var.nodes_ip4_addresses, " ", ""))[count.index + 3]
    type        = "ssh"
    agent       = false
    user        = var.worker.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline      = [
      "sudo /bin/bash /home/ubuntu/join-command"
    ]
  }
}