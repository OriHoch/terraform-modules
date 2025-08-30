variable "script" {
  type = string
  description = "Bash script to run, by default with set -euo pipefail"
}

variable "set_euo_pipefail" {
  type = bool
  default = true
}

variable "ssh_command" {
  type = string
  default = ""
}

variable "triggers_replace" {
  type = list(string)
  default = []
}

locals {
  bash_script = <<-EOT
    ${var.set_euo_pipefail ? "set -euo pipefail" : ""}
    ${var.script}
  EOT
}

resource "terraform_data" "local" {
  triggers_replace = concat(
    [
      var.ssh_command == "" ? local.bash_script : <<-EOT
        set -euo pipefail
        ${var.ssh_command} bash -c '
          set -euo pipefail
          tempfile=$(mktemp)
          trap "rm -f $tempfile" EXIT
          echo ${base64encode(local.bash_script)} | base64 -d > $tempfile
          bash $tempfile
        '
      EOT
    ],
    var.ssh_command == "" ? [] : ["${var.ssh_command} ${var.script}"],
    var.triggers_replace
  )
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = self.triggers_replace[0]
  }
}
