resource "random_string" "ubuntu_password" {
  length           = 12
  special          = true
  min_lower        = 3
  min_upper        = 3
  min_numeric      = 3
  min_special      = 3
  override_special = "%$&*_"
}