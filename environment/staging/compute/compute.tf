locals {
  # The default username for our AMI
  vm_user = "ec2-user"
}

data "terraform_remote_state" "vpc_state" {
  backend = "s3"
  config {
    bucket = "${var.vpc_state_bucket}"
    key = "${var.vpc_state_key}"
    region = "${var.region}"
    profile = "${var.profile}"
  }
}

data "aws_region" "current" {
  current = true
}

resource "aws_instance" "web" {
  count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ami = "${lookup(var.instance_amis, data.aws_region.current.name)}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${data.terraform_remote_state.vpc_state.basic_outbound_sg}"]
  subnet_id = "${data.terraform_remote_state.vpc_state.public_subnet}"

  # force Terraform to wait until a connection can be made, so that Ansible doesn't fail when trying to provision
  provisioner "remote-exec" {
    # The connection will use the local SSH agent for authentication
    inline = ["echo Successfully connected"]
    # The connection block tells our provisioner how to communicate with the resource (instance)
    connection {
      user = "${local.vm_user}"
      private_key = "${file(var.private_key_path)}"
    }
  }
}

output "web_public_ip" {
  value = ["${aws_instance.web.*.public_ip}"]
}

output "web_instance_id" {
  value = ["${aws_instance.web.*.id}"]
}

output "web_security_group" {
  value = "${data.terraform_remote_state.vpc_state.basic_outbound_sg}"
}
