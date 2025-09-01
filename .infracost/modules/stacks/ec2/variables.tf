variable "ami" {
  type    = string
  default = "ami-0c94855ba95c71c99" # sample Amazon Linux 2 (may vary by region)
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "tags" {
  type    = map(string)
  default = {}
}
