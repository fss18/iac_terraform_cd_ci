# Template to deploy the required IAM policy and IAM role for Threat Manager

#
# IAM Role for Threat Manager
#
resource "aws_iam_role" "alertlogic_cloud_defender_role" {
  name = "${var.cd_role_name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${var.alert_logic_aws_account_id}:root"
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
# IAM Policy for Threat Manager
#
resource "aws_iam_policy" "alertlogic_cloud_defender_policy" {
  name = "${var.cd_policy_name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnabledDiscoveryOfVariousAWSServices",
      "Effect": "Allow",
      "Action": [
        "autoscaling:Describe*",
        "directconnect:Describe*",
        "elasticloadbalancing:Describe*",
        "ec2:Describe*",
        "rds:Describe*",
        "rds:DownloadDBLogFilePortion",
        "rds:ListTagsForResource",
        "s3:ListAllMyBuckets",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:GetBucket*",
        "s3:GetObjectAcl",
        "s3:GetObjectVersionAcl"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EnableCloudTrailIfAccountDoesntHaveCloudTrailsEnabled",
      "Effect": "Allow",
      "Action": [
        "cloudtrail:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CreateCloudTrailS3BucketIfCloudTrailsAreBeingSetupByAlertLogic",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:PutBucketPolicy",
        "s3:DeleteBucket"
      ],
      "Resource": "arn:aws:s3:::outcomesbucket-*"
    },
    {
      "Sid": "CreateCloudTrailsTopicTfOneWasntAlreadySetupForCloudTrails",
      "Effect": "Allow",
      "Action": [
        "sns:CreateTopic",
        "sns:DeleteTopic"
      ],
      "Resource": "arn:aws:sns:*:*:outcomestopic"
    },
    {
      "Sid": "MakeSureThatCloudTrailsSnsTopicIsSetupCorrectlyForCloudTrailPublishingAndSqsSubsription",
      "Effect": "Allow",
      "Action": [
        "sns:addpermission",
        "sns:gettopicattributes",
        "sns:listtopics",
        "sns:settopicattributes",
        "sns:subscribe"
      ],
      "Resource": "arn:aws:sns:*:*:*"
    },
    {
      "Sid": "BeAbleToValidateOurRoleAndDiscoverIAM",
      "Effect": "Allow",
      "Action": [
        "iam:List*",
        "iam:Get*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CreateAlertLogicSqsQueueToSubscribeToCloudTrailsSnsTopicNotifications",
      "Effect": "Allow",
      "Action": [
        "sqs:CreateQueue",
        "sqs:DeleteQueue",
        "sqs:SetQueueAttributes",
        "sqs:GetQueueAttributes",
        "sqs:ListQueues",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueUrl"
      ],
      "Resource": "arn:aws:sqs:*:*:outcomesbucket*"
    }
  ]
}
EOF
}

#
# Link policy to role
#
resource "aws_iam_role_policy_attachment" "alertlogic_cloud_defender_attachment" {
    role       = "${aws_iam_role.alertlogic_cloud_defender_role.name}"
    policy_arn = "${aws_iam_policy.alertlogic_cloud_defender_policy.arn}"
}

#
# Set output
#
output "alertlogic_cloud_defender_target_iam_role_arn" {
  value = "${aws_iam_role.alertlogic_cloud_defender_role.arn}"
}
