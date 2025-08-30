variable "hosts_file" {
  type = string
  default = "/etc/hosts"
}

variable "ssh_command" {
  type = string
  default = ""
}

variable "needs_sudo" {
  type = bool
  default = false
}

variable "ip_hosts" {
  type = map(string)
}

variable "id_comment" {
  type = string
}

locals {
  cat_command = var.ssh_command == "" ? "cat ${var.hosts_file}" : "${var.ssh_command} cat ${var.hosts_file}"
  sudo_prefix = var.needs_sudo ? "sudo " : ""
}

resource "terraform_data" "update_hosts" {
  triggers_replace = [
    <<-EOT
      set -euo pipefail
      old_cat=$(mktemp)
      new_cat=$(mktemp)
      trap "rm -f $old_cat $new_cat" EXIT
      ${local.cat_command} > $old_cat
      cat $old_cat | python3 '${path.module}/main.py' '${jsonencode(var.ip_hosts)}' '${var.id_comment}' > $new_cat
      if ! diff $old_cat $new_cat; then
        if [ "${var.ssh_command}" = "" ]; then
          ${local.sudo_prefix}cp ${var.hosts_file} ${var.hosts_file}.bak$(date +%s)
          ${local.sudo_prefix}cp -f $new_cat ${var.hosts_file}
        else
          ${var.ssh_command} "${local.sudo_prefix}cp ${var.hosts_file} ${var.hosts_file}.bak$(date +%s)"
          cat $new_cat | ${var.ssh_command} "cat | ${local.sudo_prefix}tee ${var.hosts_file}"
        fi
      fi
    EOT
  ]
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = self.triggers_replace[0]
  }
}
