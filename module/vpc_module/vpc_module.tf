# VPC
resource "aws_vpc" "vpc_module" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "${var.vpc_name}"
  }
}

# INTERNET GW
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = "${aws_vpc.vpc_module.id}"
}

# NAT GW
resource "aws_nat_gateway" "nag_gw" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${aws_subnet.subnet-public.id}"
  depends_on    = ["aws_internet_gateway.vpc_igw"]
}

resource "aws_eip" "nat_eip" {
  vpc      = true
}

# Public Subnet
resource "aws_subnet" "subnet-public" {
  vpc_id = "${aws_vpc.vpc_module.id}"

  cidr_block        = "${var.public_subnet_cidr}"
  availability_zone = "${var.availability_zone}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.vpc_name} - Public Subnet"
    VPC = "${var.vpc_name}"
  }
}

resource "aws_route_table" "route-public" {
  vpc_id = "${aws_vpc.vpc_module.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.vpc_igw.id}"
  }

  tags {
    Name = "${var.vpc_name} - Public Subnet"
    VPC = "${var.vpc_name}"
  }
}

resource "aws_route_table_association" "route-public" {
  subnet_id      = "${aws_subnet.subnet-public.id}"
  route_table_id = "${aws_route_table.route-public.id}"
}

# Private Subnet
resource "aws_subnet" "subnet-private" {
  vpc_id = "${aws_vpc.vpc_module.id}"

  cidr_block        = "${var.private_subnet_cidr}"
  availability_zone = "${var.availability_zone}"

  tags {
    Name = "${var.vpc_name} - Private Subnet"
    VPC = "${var.vpc_name}"
  }
}

resource "aws_route_table" "route-private" {
  vpc_id = "${aws_vpc.vpc_module.id}"

  route {
    cidr_block  = "0.0.0.0/0"
    nat_gateway_id  = "${aws_nat_gateway.nag_gw.id}"
  }

  tags {
    Name = "${var.vpc_name} - Private Subnet"
    VPC = "${var.vpc_name}"
  }
}

resource "aws_route_table_association" "route-private" {
  subnet_id      = "${aws_subnet.subnet-private.id}"
  route_table_id = "${aws_route_table.route-private.id}"
}

resource "aws_security_group" "basic_outbound_sg" {
	name = "Basic allow all outbound sg"
	tags {
		Name = "Basic Outbound SG"
	}
	vpc_id = "${aws_vpc.vpc_module.id}"

	ingress	{
		protocol = "tcp"
		cidr_blocks = ["73.32.16.208/32", "4.16.218.178/32"]
		from_port = 22
		to_port = 22
	}

	egress {
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
		from_port = 0
		to_port = 0
	}
}

output "vpc_id" {
  value = "${aws_vpc.vpc_module.id}"
}

output "basic_outbound_sg" {
  value = "${aws_security_group.basic_outbound_sg.id}"
}

output "public_subnet" {
  value = "${aws_subnet.subnet-public.id}"
}

output "private_subnet" {
  value = "${aws_subnet.subnet-private.id}"
}
