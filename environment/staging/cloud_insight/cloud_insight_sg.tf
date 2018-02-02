data "terraform_remote_state" "vpc_state" {
  backend = "s3"
  config {
    bucket = "${var.vpc_state_bucket}"
    key = "${var.vpc_state_key}"
    region = "${var.region}"
    profile = "${var.profile}"
  }
}

data "aws_region" "current" {
  current = true
}

resource "aws_security_group_rule" "allow_cloud_insight_scan" {
  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = -1
  source_security_group_id = "${var.source_cloud_insight_sg}"
  security_group_id = "${var.target_security_group}"
  description = "Allow Cloud Insight to perform network scan"
}
