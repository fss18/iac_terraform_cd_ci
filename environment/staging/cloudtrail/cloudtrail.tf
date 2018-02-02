resource "aws_s3_bucket" "cloudtrail_s3_bucket" {
  bucket = "${var.cloudtrail_bucket_name}"
  force_destroy = "${var.force_delete_bucket}"
  acl = "private"
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = "${aws_s3_bucket.cloudtrail_s3_bucket.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.cloudtrail_s3_bucket.id}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.cloudtrail_s3_bucket.id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
EOF
}

resource "aws_sns_topic" "cloudtrail_sns_topic" {
  name = "${var.cloudtrail_sns_topic}"
}

resource "aws_sns_topic_policy" "cloudtrail_sns_topic_policy" {
    arn = "${aws_sns_topic.cloudtrail_sns_topic.arn}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
      "Sid": "__default_statement_ID",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "SNS:Subscribe",
        "SNS:ListSubscriptionsByTopic",
        "SNS:DeleteTopic",
        "SNS:GetTopicAttributes",
        "SNS:Publish",
        "SNS:RemovePermission",
        "SNS:AddPermission",
        "SNS:Receive",
        "SNS:SetTopicAttributes"
      ],
      "Resource": "${aws_sns_topic.cloudtrail_sns_topic.arn}",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "170945844173"
        }
      }
    },
    {
        "Sid": "AWSCloudTrailSNSPolicy20131101FromCloudTrailMainTF",
        "Effect": "Allow",
        "Principal": {"Service": "cloudtrail.amazonaws.com"},
        "Action": "SNS:Publish",
        "Resource": "${aws_sns_topic.cloudtrail_sns_topic.arn}"
    }]
}
EOF
}

resource "aws_cloudtrail" "cloudtrail_log" {
    name = "${var.cloudtrail_name}"
    s3_bucket_name = "${aws_s3_bucket.cloudtrail_s3_bucket.id}"
    include_global_service_events = true
    is_multi_region_trail = true
    sns_topic_name = "${var.cloudtrail_sns_topic}"
    depends_on = ["aws_s3_bucket_policy.cloudtrail_bucket_policy", "aws_sns_topic_policy.cloudtrail_sns_topic_policy"]
}

output "cloudtrail_sns_topic" {
  value = "${aws_sns_topic.cloudtrail_sns_topic.id}"
}

output "cloudtrail_s3_bucket" {
  value = "${aws_s3_bucket.cloudtrail_s3_bucket.id}"
}
