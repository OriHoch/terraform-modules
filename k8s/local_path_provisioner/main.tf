variable "local_path_provisioner_version" {
  type = string
}

variable "ssh_command" {
  type = string
  default = ""
}

variable "kubectl" {
  type = string
}

variable "set_default_class" {
  type = bool
  default = true
}

module "install" {
  source = "git::https://github.com/orihoch/terraform-modules.git//bash_exec?ref=59d2bb2ae67d9cef3e63816c905f33b899810623"
  ssh_command = var.ssh_command
  script = <<-EOT
    ${var.kubectl} apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/${var.local_path_provisioner_version}/deploy/local-path-storage.yaml
    if [ "${var.set_default_class}" = "true" ]; then
      ${var.kubectl} patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    fi
  EOT
}
