#TODO = set this to variables
provider "aws" {
    profile = "${var.profile}"
    shared_credentials_file = "${var.cred_file}"
    region = "${var.region}"
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

variable "bucket_name" {
  type = "string"
}

variable "table_name" {
  type = "string"
}
