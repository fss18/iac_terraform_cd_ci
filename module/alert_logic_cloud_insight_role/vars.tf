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
variable "ci_role_name" {
  type = "string"
}

#
# Name of the IAM policy
#
variable "ci_policy_name" {
  type = "string"
}
