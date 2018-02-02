#gather all vpc ID into list in
data "template_file" "vpc_list" {
  count = 1
  template = "${file("${path.module}/vpclist.tpl")}"
  vars {
    region = "${var.region}"
    vpc_id = "${module.vpc_master.vpc_id}"
  }
}

#add the list to scope template
data "template_file" "cloud_insight_scope" {
  template = "${file("${path.module}/ci_scope.tpl")}"
  vars {
    vpc_list = "${join(",",data.template_file.vpc_list.*.rendered)}"
  }
}

#provide the output so it can be written to file
output "cloud_insight_scope" {
	value = ["${data.template_file.cloud_insight_scope.rendered}"]
}
