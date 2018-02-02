# Template to deploy the required IAM policy and IAM role for Cloud Insight
#
# IAM Role for Cloud Insight
#
resource "aws_iam_role" "alertlogic_cloud_insight_role" {
  name = "${var.ci_role_name}"
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
# IAM Policy for Cloud Insight
#
resource "aws_iam_policy" "alertlogic_cloud_insight_policy" {
  name = "${var.ci_policy_name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EnabledDiscoveryOfVariousAWSServices",
            "Effect": "Allow",
            "Action": [
                "autoscaling:Describe*",
                "cloudformation:DescribeStack*",
                "cloudformation:GetTemplate",
                "cloudformation:ListStack*",
                "cloudfront:Get*",
                "cloudfront:List*",
                "cloudwatch:Describe*",
                "directconnect:Describe*",
                "dynamodb:ListTables",
                "ec2:Describe*",
                "elasticbeanstalk:Describe*",
                "elasticache:Describe*",
                "elasticloadbalancing:Describe*",
                "elasticmapreduce:DescribeJobFlows",
                "events:Describe*",
                "events:List*",
                "glacier:ListVaults",
                "guardduty:Get*",
                "guardduty:List*",
                "kinesis:Describe*",
                "kinesis:List*",
                "lambda:List*",
                "logs:Describe*",
                "rds:Describe*",
                "rds:DownloadDBLogFilePortion",
                "rds:ListTagsForResource",
                "redshift:Describe*",
                "route53:GetHostedZone",
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets",
                "sdb:DomainMetadata",
                "sdb:ListDomains",
                "s3:ListAllMyBuckets",
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:GetBucket*",
                "s3:GetLifecycleConfiguration",
                "s3:GetObjectAcl",
                "s3:GetObjectVersionAcl"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EnableInsightDiscovery",
            "Effect": "Allow",
            "Action": [
                "iam:Get*",
                "iam:List*",
                "iam:ListRoles",
                "iam:GetRolePolicy",
                "iam:GetAccountSummary",
                "iam:GenerateCredentialReport"
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
                "sns:listtopics",
                "sns:settopicattributes",
                "sns:gettopicattributes",
                "sns:subscribe"
            ],
            "Resource": "arn:aws:sns:*:*:*"
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
        },
        {
            "Sid": "EnableAlertLogicSecurityInfrastructureDeployment",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:CreateSubnet",
                "ec2:CreateInternetGateway",
                "ec2:AttachInternetGateway",
                "ec2:CreateRoute",
                "ec2:CreateRouteTable",
                "ec2:AssociateRouteTable",
                "ec2:CreateSecurityGroup",
                "ec2:CreateKeyPair",
                "ec2:ImportKeyPair",
                "ec2:CreateNetworkAclEntry"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ModifyNetworkSettingsToEnableNetworkVisibilityFromAlertLogicSecurityAppliance",
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:DeleteSecurityGroup",
                "ec2:DeleteNetworkAclEntry",
                "ec2:DeleteRouteTable"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:security-group/*",
                "arn:aws:ec2:*:*:route-table/*",
                "arn:aws:ec2:*:*:network-acl/*"
            ],
            "Condition": {
                "StringEquals": {
                    "ec2:ResourceTag/AlertLogic": "Security"
                }
            }
        },
        {
            "Sid": "DeleteSecuritySubnet",
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteSubnet"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EnabledLaunchingAlertLogicSecurityAppliancesInAlertLogicSubnet",
            "Effect": "Allow",
            "Action": [
                "ec2:RunInstances"
            ],
            "Resource": "arn:aws:ec2:*:*:subnet/*",
            "Condition": {
                "StringEquals": {
                    "ec2:ResourceTag/AlertLogic": "Security"
                }
            }
        },
        {
            "Sid": "EnabledLaunchingAlertLogicSecurityAppliancesFromAlertLogicAmi",
            "Effect": "Allow",
            "Action": [
                "ec2:RunInstances"
            ],
            "Resource": "arn:aws:ec2:*::image/ami-*",
            "Condition": {
                "StringEquals": {
                    "ec2:Owner": "733251395267"
                }
            }
        },
        {
            "Sid": "EnsureThatAlertLogicApplianceCanCreateNecessaryResources",
            "Effect": "Allow",
            "Action": [
                "ec2:RunInstances"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:instance/*",
                "arn:aws:ec2:*:*:volume/*",
                "arn:aws:ec2:*:*:network-interface/*",
                "arn:aws:ec2:*:*:key-pair/*",
                "arn:aws:ec2:*:*:security-group/*"
            ]
        },
        {
            "Sid": "EnabletAlertLogicApplianceStateManagement",
            "Effect": "Allow",
            "Action": [
                "ec2:TerminateInstances",
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*",
            "Condition": {
                "StringEquals": {
                    "ec2:ResourceTag/AlertLogic": "Security"
                }
            }
        },
        {
            "Sid": "EnableAlertLogicAutoScalingGroup",
            "Effect": "Allow",
            "Action": [
                "autoscaling:CreateLaunchConfiguration",
                "autoscaling:DeleteLaunchConfiguration",
                "autoscaling:CreateAutoScalingGroup",
                "autoscaling:DeleteAutoScalingGroup"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#
# Link policy to role
#
resource "aws_iam_role_policy_attachment" "alertlogic_cloud_insight_attachment" {
    role       = "${aws_iam_role.alertlogic_cloud_insight_role.name}"
    policy_arn = "${aws_iam_policy.alertlogic_cloud_insight_policy.arn}"
}

#
# Set output
#
output "alertlogic_cloud_insight_target_iam_role_arn" {
  value = "${aws_iam_role.alertlogic_cloud_insight_role.arn}"
}
