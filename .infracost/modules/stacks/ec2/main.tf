resource "aws_instance" "example" {
  ami           = var.ami
  instance_type = var.instance_type

  tags = merge({
    Name = "infracost-ec2-example"
  }, var.tags)
}
