output "master" {
  value = var.dhcp == true ? vsphere_virtual_machine.master[0].default_ip_address : split(",", replace(var.nodes_ip4_addresses, " ", ""))[0]
}

output "workers" {
  value = var.dhcp == true ? vsphere_virtual_machine.workers.*.default_ip_address : slice(split(",", replace(var.nodes_ip4_addresses, " ", "")), 3, length(split(",", replace(var.nodes_ip4_addresses, " ", ""))))
}

output "ubuntu_username" {
  value = var.master.username
}

output "ubuntu_password" {
  value = var.ubuntu_password == null ? random_string.ubuntu_password.result : var.ubuntu_password
}

output "ssh_private_key_path" {
  value = "~/.ssh/${var.ssh_key.private_key_name}.pem"
}