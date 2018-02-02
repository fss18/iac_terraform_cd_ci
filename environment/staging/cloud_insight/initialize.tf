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

variable "source_cloud_insight_sg" {
  type = "string"
}

variable "target_security_group" {
  type = "string"
}

variable "vpc_state_bucket" {
  type = "string"
}

variable "vpc_state_key" {
  type = "string"
}
