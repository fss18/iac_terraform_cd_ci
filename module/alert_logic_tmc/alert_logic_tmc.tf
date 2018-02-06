# Create a security group policy and setup rules for Threat Manager appliance
data "aws_region" "current" {
  current = true
}

resource "aws_security_group" "tmc_sg" {
	name = "Alert Logic Threat Manager Security Group"
	tags {
		Name = "Alert Logic Threat Manager Security Group"
	}
	vpc_id = "${var.vpc_id}"

	ingress	{
		protocol = "tcp"
		cidr_blocks = ["204.110.218.96/27"]
		from_port = 22
		to_port = 22
	}
	ingress	{
		protocol = "tcp"
		cidr_blocks = ["204.110.219.96/27"]
		from_port = 22
		to_port = 22
	}
	ingress	{
		protocol = "tcp"
		cidr_blocks = ["208.71.209.32/27"]
		from_port = 22
		to_port = 22
	}
	ingress	{
		protocol = "tcp"
		cidr_blocks = ["${var.monitoringCIDR}"]
		from_port = 7777
		to_port = 7777
	}
	ingress	{
		protocol = "tcp"
		cidr_blocks = ["${var.monitoringCIDR}"]
		from_port = 443
		to_port = 443
	}
	ingress	{
		protocol = "tcp"
		cidr_blocks = ["${var.claimCIDR}"]
		from_port = 80
		to_port = 80
	}
	egress {
		protocol = "tcp"
		cidr_blocks = ["204.110.218.96/27"]
		from_port = 443
		to_port = 443
	}
	egress {
		protocol = "tcp"
		cidr_blocks = ["204.110.219.96/27"]
		from_port = 443
		to_port = 443
	}
	egress {
		protocol = "tcp"
		cidr_blocks = ["204.110.218.96/27"]
		from_port = 4138
		to_port = 4138
	}
	egress {
		protocol = "tcp"
		cidr_blocks = ["204.110.219.96/27"]
		from_port = 4138
		to_port = 4138
	}
	egress {
		protocol = "tcp"
		cidr_blocks = ["208.71.209.32/27"]
		from_port = 443
		to_port = 443
	}
	egress {
		protocol = "tcp"
		cidr_blocks = ["208.71.209.32/27"]
		from_port = 4138
		to_port = 4138
	}
	egress {
		protocol = "udp"
		cidr_blocks = ["8.8.8.8/32"]
		from_port = 53
		to_port = 53
	}
	egress {
		protocol = "udp"
		cidr_blocks = ["8.8.4.4/32"]
		from_port = 53
		to_port = 53
	}
	egress {
		protocol = "tcp"
		cidr_blocks = ["8.8.8.8/32"]
		from_port = 53
		to_port = 53
	}
	egress {
		protocol = "tcp"
		cidr_blocks = ["8.8.4.4/32"]
		from_port = 53
		to_port = 53
	}
	egress {
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
		from_port = 80
		to_port = 80
	}
}

# Launch a Threat Manager instance from a shared AMI
resource "aws_instance" "tmc" {
	ami = "${lookup(var.aws_amis, data.aws_region.current.name)}"
	instance_type = "${var.instance_type}"
	subnet_id = "${var.subnet_id}"
	vpc_security_group_ids = ["${aws_security_group.tmc_sg.id}"]
	tags {
		Name = "${var.tag_name}"
	}
	depends_on = ["aws_security_group.tmc_sg"]
}

# Allocate a new Elastic IP to be associated with the new Threat Manager instance
resource "aws_eip" "tmc" {
	instance = "${aws_instance.tmc.id}"
	vpc      = true
	depends_on = ["aws_instance.tmc"]
}

# Outputs
output "public_ip" {
	value = "${aws_eip.tmc.public_ip}"
}

output "private_ip" {
	value = "${aws_eip.tmc.private_ip}"
}

output "instance_id" {
	value = "${aws_instance.tmc.id}"
}

output "sg_id" {
	value = "${aws_security_group.tmc_sg.id}"
}
