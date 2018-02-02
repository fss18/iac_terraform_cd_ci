data "terraform_remote_state" "vpc_state" {
  backend = "s3"
  config {
    bucket = "${var.vpc_state_bucket}"
    key = "${var.vpc_state_key}"
    region = "${var.region}"
    profile = "${var.profile}"
  }
}

module "alert_logic_tmc" {
  source = "../../../module/alert_logic_tmc"
  vpc_id = "${data.terraform_remote_state.vpc_state.vpc_id}"
  subnet_id = "${data.terraform_remote_state.vpc_state.public_subnet}"
  instance_type = "${var.instance_type}"
  tag_name = "${var.tag_name}"
  claimCIDR = "${var.claimCIDR}"
  monitoringCIDR = "${data.terraform_remote_state.vpc_state.vpc_cidr}"
}

resource "null_resource" "check_tmc_claim" {
  triggers {
    #tmc_launch = "${module.alert_logic_tmc.public_ip}"
    tmc_launch = "${uuid()}"
  }
  provisioner "local-exec" {
    command = <<EOT
      echo ${module.alert_logic_tmc.private_ip} > private_ips.txt
      echo ${module.alert_logic_tmc.public_ip} > public_ips.txt
    EOT
  }
}

output "tmc_public_ip" {
  value = "${module.alert_logic_tmc.public_ip}"
}

output "tmc_internal_ip" {
  value = "${module.alert_logic_tmc.private_ip}"
}

output "tmc_instance_id" {
  value = "${module.alert_logic_tmc.instance_id}"
}

output "tmc_sg_id" {
  value = "${module.alert_logic_tmc.sg_id}"
}
