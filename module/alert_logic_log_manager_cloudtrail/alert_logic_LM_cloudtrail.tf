# Template to deploy new SQS, IAM policy and IAM role for Log Manager to consume CloudTrail

data "aws_region" "current" {
  current = true
}

#
# SQS to read data from CloudTrail
#
resource "aws_sqs_queue" "alertlogic_lm_cloudtrail_sqs" {
  name = "${var.cloudtrail_sqs_name}"
}

#
# SQS policy to subscribe to CloudTrail SNS
#
resource "aws_sqs_queue_policy" "alertlogic_lm_cloudtrail_sqs_policy" {
  queue_url = "${aws_sqs_queue.alertlogic_lm_cloudtrail_sqs.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "1",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.alertlogic_lm_cloudtrail_sqs.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${var.cloudtrail_sns_arn}"
        }
      }
    }
  ]
}
POLICY
}

#
# Subscribe SQS to CloudTrail SNS
#
resource "aws_sns_topic_subscription" "alertlogic_lm_cloudtrail_sqs_subscribe" {
  topic_arn = "${var.cloudtrail_sns_arn}"
  protocol  = "sqs"
  endpoint  = "${aws_sqs_queue.alertlogic_lm_cloudtrail_sqs.arn}"
}

#
# IAM Role for Log Manager to collect CloudTrail
#
resource "aws_iam_role" "alertlogic_lm_cloudtrail_role" {
  name = "${var.cloudtrail_role_name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${var.alert_logic_lm_aws_account_id}:root"
      },
      "Condition": {
        "StringEquals": {"sts:ExternalId": "${var.alert_logic_external_id}"}
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

#
# IAM Policy for Log Manager to collect CloudTrail
#
resource "aws_iam_policy" "alertlogic_lm_cloudtrail_policy" {
  name = "${var.cloudtrail_role_name}-policy"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Sid": "1",
       "Action": [
         "sqs:GetQueueUrl",
         "sqs:Receivemessage",
         "sqs:DeleteMessage"
      ],
      "Effect": "Allow",
      "Resource": "${aws_sqs_queue.alertlogic_lm_cloudtrail_sqs.arn}"
     },
     {
       "Sid": "2",
       "Action": [
          "s3:GetObject"
       ],
       "Effect": "Allow",
       "Resource": "arn:aws:s3:::${var.cloudtrail_s3}/*"
     }
   ]
 }
EOF
}

#
# Link policy to role
#
resource "aws_iam_role_policy_attachment" "alertlogic_lm_cloudtrail_attachment" {
    role       = "${aws_iam_role.alertlogic_lm_cloudtrail_role.name}"
    policy_arn = "${aws_iam_policy.alertlogic_lm_cloudtrail_policy.arn}"
}

#
# Set output
#
output "alertlogic_lm_cloudtrail_target_iam_role_arn" {
  value = "${aws_iam_role.alertlogic_lm_cloudtrail_role.arn}"
}

output "alertlogic_lm_cloudtrail_target_sqs_name" {
  value = "${aws_sqs_queue.alertlogic_lm_cloudtrail_sqs.name}"
}

output "alertlogic_lm_cloudtrail_target_sqs_region" {
  value = "${data.aws_region.current.name}"
}
