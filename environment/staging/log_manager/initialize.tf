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

variable "alert_logic_lm_aws_account_id" {
  type = "string"
}

variable "alert_logic_external_id" {
  type = "string"
}

variable "cloudtrail_sns_arn" {
  type = "string"
}

variable "cloudtrail_s3" {
  type = "string"
}

variable "cloudtrail_sqs_name" {
  type = "string"
}

variable "cloudtrail_role_name" {
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
