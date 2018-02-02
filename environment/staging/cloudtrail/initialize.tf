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

variable "cloudtrail_sns_topic" {
  type = "string"
}

variable "cloudtrail_bucket_name" {
  type = "string"
}

variable "cloudtrail_name" {
  type = "string"
}

variable "force_delete_bucket" {
  default = false
}
