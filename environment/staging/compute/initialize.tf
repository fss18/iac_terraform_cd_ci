provider "aws" {
    profile = "${var.profile}"
    shared_credentials_file = "${var.cred_file}"
    region = "${var.region}"
}

terraform {
  backend "s3" {
    #Use partial parameter during terraform init
  }
}

variable "key_name" {
  type = "string"
}

variable "instance_type" {
  type = "string"
}

variable "instance_count" {
  type = "string"
}

variable "private_key_path" {
  type = "string"
}

variable "region" {
  description = "AWS region"
  type = "string"
}

variable "profile" {
  type = "string"
}

variable "cred_file" {
  type = "string"
}

variable "vpc_state_bucket" {
  type = "string"
}

variable "vpc_state_key" {
  type = "string"
}

variable "instance_amis" {
  default = {
    us-east-1 = "ami-97785bed"
		us-east-2 = "ami-f63b1193"
		us-west-1 = "ami-824c4ee2"
		us-west-2 = "ami-f2d3638a"
    ap-south-1 = "ami-531a4c3c"
    ap-southeast-1 = "ami-68097514"
    ap-southeast-2 = "ami-942dd1f6"
    ap-northeast-1 = "ami-ceafcba8"
    ap-northeast-2 = "ami-863090e8"
    ca-central-1 = "ami-a954d1cd"
    eu-central-1 = "ami-5652ce39"
    eu-west-1 = "ami-d834aba1"
    eu-west-2 = "ami-403e2524"
    eu-west-3 = "ami-8ee056f3"
    sa-east-1 = "ami-84175ae8"
  }
}
