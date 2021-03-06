# Set variables
variable "vpc_id" {
	description = "VPC into which Threat Manager will be deployed (Must have available EIPs)."
  type = "string"
}

variable "subnet_id" {
	description = "ID of a DMZ subnet, with a default route to an IGW, into which Threat Manager will be deployed."
  type = "string"
}

variable "instance_type" {
	description = "EC2 Instance Type Threat Manager will be spun up as (Supported: c3.large, c3.xlarge, c3.2xlarge, c4.large, c4.xlarge, c4.2xlarge)."
  type = "string"
}

variable "tag_name" {
	description = "Provide a tag name for your Threat Manager instance."
  type = "string"
}
variable "claimCIDR" {
	description = "CIDR netblock which will be submitting the web form that the appliance serves for claiming over port 80 (This rule can be removed after the appliance has been claimed)."
  type = "string"
}

variable "monitoringCIDR" {
	description = "CIDR netblock to be monitored (Where agents will be installed)."
  type = "string"
}

variable "aws_amis" {
  default = {
		ap-south-1 = "ami-f6ccb499"
		eu-west-2 = "ami-321d0c56"
		eu-west-1 = "ami-b6c52ecf"
		ap-northeast-2 = "ami-26a17848"
		ap-northeast-1 = "ami-dd17f5bb"
		sa-east-1 = "ami-a9b8cfc5"
		ca-central-1 = "ami-9e0db2fa"
		ap-southeast-1 = "ami-a4d24fc7"
		ap-southeast-2 = "ami-9dbda2fe"
		eu-central-1 = "ami-909438ff"
		us-east-1 = "ami-c2a8f7b9"
		us-east-2 = "ami-322f0f57"
		us-west-1 = "ami-8b765eeb"
		us-west-2 = "ami-cb9f85b2"
  }
}
