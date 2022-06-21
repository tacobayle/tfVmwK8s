
resource "tls_private_key" "ssh" {
  algorithm = var.ssh_key.algorithm
  rsa_bits  = var.ssh_key.rsa_bits
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = pathexpand("~/.ssh/${var.ssh_key.private_key_name}.pem")
  file_permission = var.ssh_key.file_permission
}

resource "null_resource" "clear_ssh_key_locally" {
  count = length(split(",", replace(var.nodes_ip4_addresses, " ", "")))
  provisioner "local-exec" {
    command = "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${split(",", replace(var.nodes_ip4_addresses, " ", ""))[count.index]}\" || true"
  }
}