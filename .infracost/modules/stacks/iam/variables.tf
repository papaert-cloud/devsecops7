variable "user_name" {
  type    = string
  default = "infracost-user"
}

variable "tags" {
  type    = map(string)
  default = {}
}
