## Network backbone ##
module "vpc_master" {
  source = "../../../module/vpc_module"
  vpc_name = "${var.vpc_name}"
  vpc_cidr = "${var.vpc_cidr}"
  public_subnet_cidr = "${var.public_subnet_cidr}"
  private_subnet_cidr = "${var.private_subnet_cidr}"
  availability_zone = "${var.availability_zone}"
}

output "vpc_id" {
  value = "${module.vpc_master.vpc_id}"
}

output "basic_outbound_sg" {
  value = "${module.vpc_master.basic_outbound_sg}"
}

output "public_subnet" {
  value = "${module.vpc_master.public_subnet}"
}

output "private_subnet" {
  value = "${module.vpc_master.private_subnet}"
}

output "vpc_cidr" {
  value = "${var.vpc_cidr}"
}
