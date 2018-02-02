#build list of public ips and instance ids
locals {
  web_ip_address = ["${aws_instance.web.*.public_ip}"]
  web_host_name = ["${aws_instance.web.*.id}"]
}

#build list of host within the same category
data "template_file" "web_server_list" {
  count = "${var.instance_count}"
  template = "${file("${path.module}/hostname.tpl")}"
  vars {
    name = "${local.web_host_name[count.index]}"
    extra = "ansible_host=${local.web_ip_address[count.index]} ansible_user=ec2-user"
  }
}

#merge the host list to inventory file
data "template_file" "ansible_inventory" {
  template = "${file("${path.module}/ansible_inventory.tpl")}"
  vars {
    env = "production"
    web_hosts = "${join("",data.template_file.web_server_list.*.rendered)}"
  }
}

#provide the output so it can be written to file
output "ansible_inventory" {
	value = "${data.template_file.ansible_inventory.rendered}"
}
