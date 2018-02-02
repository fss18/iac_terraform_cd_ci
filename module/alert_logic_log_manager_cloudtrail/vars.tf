#Variables Declarations
#
# External ID for Cross Account
#
variable "alert_logic_external_id" {
  type = "string"
}

#
# IAM Role name for Log Manager CloudTrail
#
variable "cloudtrail_role_name" {
  type = "string"
}

#
# SNS arn from the CloudTrail
#
variable "cloudtrail_sns_arn" {
  type = "string"
}

#
# S3 bucket name where the CloudTrail stored
#
variable "cloudtrail_s3" {
  type = "string"
}

#
# SQS Name, where SNS will send notification for new CloudTrail logs
#
variable "cloudtrail_sqs_name" {
  type = "string"
}

#
# This is the AWS Account id for Alert Logic
#
variable "alert_logic_lm_aws_account_id" {
  type = "string"
}
