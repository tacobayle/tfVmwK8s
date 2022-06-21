
resource "null_resource" "download_ubuntu" {
  provisioner "local-exec" {
    command = "curl -s -o /tmp/$(basename ${var.content_library.source_url}) ${var.content_library.source_url}"
  }
}

resource "vsphere_content_library" "library" {
  name            = "${var.content_library.basename}${random_string.id.result}"
  storage_backing = [data.vsphere_datastore.datastore.id]
}

resource "vsphere_content_library_item" "file" {
  depends_on = [null_resource.download_ubuntu]
  name        = basename(var.content_library.source_url)
  library_id  = vsphere_content_library.library.id
  file_url = "/tmp/${basename(var.content_library.source_url)}"
}

resource "null_resource" "remove_download_ubuntu" {
  depends_on = [vsphere_content_library_item.file]
  provisioner "local-exec" {
    command = "rm -f /tmp/$(basename ${var.content_library.source_url})"
  }
}