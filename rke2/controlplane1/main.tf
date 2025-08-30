variable "rke2_version" {
  type = string
  description = "rke2 version, e.g. v1.33.4+rke2r1"
}

variable "rke2_config" {
  type = any
  description = "rke2 config as terraform object, will be converted to yaml"
}

variable "local_kubeconfig_replace_ip" {
  type = string
  description = "IP to replace in kubeconfig file instead of 127.0.0.1"
}

variable "local_kubeconfig_path" {
  type = string
  description = "Path in local PC to save the kubeconfig file to with replaced IP"
}

variable "local_kubeconfig_chown" {
  type = string
  description = "User to chown the local kubeconfig file to, empty for no chown"
  default = ""
}

variable "ssh_command" {
  type = string
  default = ""
}

variable "triggers_replace" {
  type = list(string)
  default = []
}

module "install" {
  source = "git::https://github.com/orihoch/terraform-modules.git//bash_exec?ref=59d2bb2ae67d9cef3e63816c905f33b899810623"
  ssh_command = var.ssh_command
  script = <<-EOT
    mkdir -p /etc/rancher/rke2/
    echo "${yamlencode(var.rke2_config)}" > /etc/rancher/rke2/config.yaml
    curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=${var.rke2_version} sh -
    if systemctl is-active --quiet rke2-server.service; then
      systemctl restart rke2-server.service
    else
      systemctl enable rke2-server.service
      systemctl start rke2-server.service
    fi
  EOT
}

resource "terraform_data" "kubeconfig" {
  triggers_replace = concat([
    <<-EOT
      set -euo pipefail
      mkdir -p $(dirname "${var.local_kubeconfig_path}")
      if [ "${var.ssh_command}" = "" ]; then
        cp -f /etc/rancher/rke2/rke2.yaml "${var.local_kubeconfig_path}"
      else
        ${var.ssh_command} "cat /etc/rancher/rke2/rke2.yaml" > "${var.local_kubeconfig_path}"
      fi
      sed -i 's/127.0.0.1/${var.local_kubeconfig_replace_ip}/g' "${var.local_kubeconfig_path}"
      if [ "${var.local_kubeconfig_chown}" != "" ]; then
        chown ${var.local_kubeconfig_chown} "${var.local_kubeconfig_path}"
      fi
    EOT
  ], var.triggers_replace)
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = self.triggers_replace[0]
  }
}
