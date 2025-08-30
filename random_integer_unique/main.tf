variable "min" {
  type = number
}

variable "max" {
  type = number
}

variable "allocation_ids" {
  type = list(string)
  description = "List of IDs to allocate numbers to, each ID will get a unique number"
}

variable "blocked_numbers" {
  type = list(number)
  default = []
  description = "List of numbers that should not be allocated"
}

variable "state_file" {
  type = string
  description = "Path to a file to save the state of allocated numbers, so that re-running terraform will not re-allocate numbers"
}

data "external" "allocations" {
  program = ["python3", "${path.module}/main.py", var.min, var.max, jsonencode(var.allocation_ids), jsonencode(var.blocked_numbers), var.state_file]
}

output "allocations" {
  value = data.external.allocations.result
}
