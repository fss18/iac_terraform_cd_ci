## IAM related modules ##
module "cloud_insight_role" {
  source = "../../../module/alert_logic_cloud_insight_role"
  alert_logic_aws_account_id = "${var.alert_logic_aws_account_id}"
  alert_logic_external_id = "${var.alert_logic_external_id}"
  ci_role_name = "${var.ci_role_name}"
  ci_policy_name = "${var.ci_policy_name}"
}

module "cloud_defender_role" {
  source = "../../../module/alert_logic_cloud_defender_role"
  alert_logic_aws_account_id = "${var.alert_logic_aws_account_id}"
  alert_logic_external_id = "${var.alert_logic_external_id}"
  cd_role_name = "${var.cd_role_name}"
  cd_policy_name = "${var.cd_policy_name}"
}
