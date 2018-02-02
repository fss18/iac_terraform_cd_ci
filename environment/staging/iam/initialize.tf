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

variable "alert_logic_aws_account_id" {
  type = "string"
}

variable "alert_logic_external_id" {
  type = "string"
}

variable "ci_role_name" {
  type = "string"
}

variable "ci_policy_name" {
  type = "string"
}

variable "cd_role_name" {
  type = "string"
}

variable "cd_policy_name" {
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
