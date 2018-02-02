#Variables Declarations

#
# This is the AWS Account id for Alert Logic
#
variable "alert_logic_aws_account_id" {
  type = "string"
}

#
# External ID for Cross Account
#
variable "alert_logic_external_id" {
  type = "string"
}

#
# Name of the IAM role
#
variable "cd_role_name" {
  type = "string"
}

#
# Name of the IAM policy
#
variable "cd_policy_name" {
  type = "string"
}
