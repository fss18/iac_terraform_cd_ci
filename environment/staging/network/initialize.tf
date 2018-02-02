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

variable "vpc_name" {
  description = "VPC NAme"
  type = "string"
}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  type = "string"
}

variable "public_subnet_cidr" {
  description = "CIDR for the Public Subnet"
  type = "string"
}

variable "private_subnet_cidr" {
  description = "CIDR for the Private Subnet"
  type = "string"
}

variable "availability_zone" {
  description = "Availabilite Zone"
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
