## IAM related modules ##
module "log_manager_cloudtrail" {
  source = "../../../module/alert_logic_log_manager_cloudtrail"
  alert_logic_lm_aws_account_id = "${var.alert_logic_lm_aws_account_id}"
  alert_logic_external_id = "${var.alert_logic_external_id}"
  cloudtrail_sns_arn = "${var.cloudtrail_sns_arn}"
  cloudtrail_s3 = "${var.cloudtrail_s3}"
  cloudtrail_sqs_name= "${var.cloudtrail_sqs_name}"
  cloudtrail_role_name= "${var.cloudtrail_role_name}"
}

output "alertlogic_lm_cloudtrail_target_iam_role_arn" {
  value = "${module.log_manager_cloudtrail.alertlogic_lm_cloudtrail_target_iam_role_arn}"
}

output "alertlogic_lm_cloudtrail_target_sqs_name" {
  value = "${module.log_manager_cloudtrail.alertlogic_lm_cloudtrail_target_sqs_name}"
}

output "alertlogic_lm_cloudtrail_target_sqs_region" {
  value = "${var.region}"
}
