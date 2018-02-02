#!/bin/bash
#Text color
RED='\033[0;33m'
NC='\033[0m' # No Color

function display_help() {
  printf "\n${RED}*****************************************************************************${NC}\n"
  printf "${RED}Required parameters:${NC}\n"
  printf " --profile   AWS_PROFILE \n"
  printf " --S3        S3 Bucket Name where the Terraform State are stored \n"
  printf " --user      Username or Access Key to Cloud Insight \n"
  printf " --pass      Password or Secret Key to Cloud Insight \n"
  printf " --apikey    User API KEY for Cloud Defender \n"
  printf " --dc        Select either: DENVER/ASHBURN/NEWPORT \n"
  printf " --cid       Your AlertLogic Customer ID / CID \n"
  printf " --name      Project Name which will be prefix on most of the resource name \n"
  printf " --env       Name of the environment, must exist under ./environment/ directory \n"
  printf "\n${RED}*****************************************************************************${NC}\n"
}

if [ $# -lt 1 ]
then
  display_help
  exit 1
fi

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --profile)
      PROFILE="$2"
      shift
      shift
      ;;
    --S3)
      S3="$2"
      shift
      shift
      ;;
    --user)
      USER="$2"
      shift
      shift
      ;;
    --pass)
      PASS="$2"
      shift
      shift
      ;;
    --apikey)
      APIKEY="$2"
      shift
      shift
      ;;
    --dc)
      DC="$2"
      shift
      shift
      ;;
    --cid)
      CID="$2"
      shift
      shift
      ;;
    --name)
      NAME="$2"
      shift
      shift
      ;;
    --env)
      ENV="$2"
      shift
      shift
      ;;
    -h|--h)
      display_help
      exit
      ;;
    *)
      printf "${RED}Wrong argument $1 ${NC}\n\n"
      exit 1
  esac
done

### CONSTANT ###
KEY="state/$ENV/iam" #path to s3 bucket where IAM related state are stored

#Get pwd
reldir=`dirname $0`
cd $reldir
cd ../
DIRECTORY=`pwd`
ENV="staging"
printf "\n${RED}PROJECT DIRECTORY=${NC} $DIRECTORY\n"



#destroy AlertLogic Cloud Insight security group modification
printf "\n${RED}### REMOVE REFERENCE TO CLOUD INSIGHT SECURITY GROUPS${NC}\n"
cd $DIRECTORY/environment/$ENV/compute
TARGET_SG=`terraform output web_security_group`
cd $DIRECTORY/environment/$ENV/cloud_insight
SOURCE_CI_SG=`cat $DIRECTORY/environment/$ENV/cloud_insight/cloud_insight_sg_id.txt`
terraform destroy -force -var-file=$DIRECTORY/environment/$ENV/cloud_insight/vars.tfvars -var "source_cloud_insight_sg=$SOURCE_CI_SG" -var "target_security_group=$TARGET_SG"

#destroy Cloud Insight Deployment
cd $DIRECTORY/scripts
printf "\n${RED}### DESTROY ALERTLOGIC CLOUD INSIGHT DEPLOYMENT${NC}\n"
MODE="CI_DESTROY"
python deploy_alertlogic.py -profile $PROFILE -s3 $S3 -key $KEY -mode $MODE -u $USER -p $PASS -dc $DC -cid $CID -name $NAME
ret=$?
if [ $ret -ne 0 ]; then
  printf "\n${RED}### Exit from script, reason: cannot destroy Cloud Insight deployment - this is dependency before destroying VPC${NC}\n\n"
  exit 1
fi


#destroy Cloud Defender Deployment
printf "\n${RED}### DESTROY ALERTLOGIC CLOUD DEFENDER DEPLOYMENT${NC}\n"
cd $DIRECTORY/scripts
MODE="CD_DESTROY"
python deploy_alertlogic.py -profile $PROFILE -s3 $S3 -key $KEY -mode $MODE -u $USER -p $PASS -dc $DC  -cid $CID -name $NAME
if [ $ret -ne 0 ]; then
  printf "\n${RED}### Exit from script, reason: cannot launch Cloud Defender deployment${NC}\n\n"
  exit 1
fi


#destroy AlertLogic Threat Manager stuff
printf "\n${RED}### DESTROY ALERTLOGIC THREAT MANAGER APPLIANCE${NC}\n"
cd $DIRECTORY/environment/$ENV/threat_manager
terraform destroy -force -var-file=$DIRECTORY/environment/$ENV/threat_manager/vars.tfvars


#destroy Compute stuff
printf "\n${RED}### DESTROY COMPUTE RESOURCE${NC}\n"
cd $DIRECTORY/environment/$ENV/compute
terraform destroy -force -var-file=$DIRECTORY/environment/$ENV/compute/vars.tfvars


#destroy Network stuff
printf "\n${RED}### DESTROY VPC RESOURCE${NC}\n"
cd $DIRECTORY/environment/$ENV/network
terraform destroy -force -var-file=$DIRECTORY/environment/$ENV/network/vars.tfvars


#Destroy AlertLogic Log Manager for CloudTrail
printf "\n${RED}### DESTROY ALERTLOGIC LOG MANAGER RESOURCES${NC}\n"
##Get CloudTrail Output / State
cd $DIRECTORY/environment/$ENV/cloudtrail
LM_SNS=`terraform output cloudtrail_sns_topic`
LM_S3=`terraform output cloudtrail_s3_bucket`
##Get Log Manager related Output / State
cd $DIRECTORY/environment/$ENV/log_manager
LM_ARN=`terraform output alertlogic_lm_cloudtrail_target_iam_role_arn`
LM_SQS=`terraform output alertlogic_lm_cloudtrail_target_sqs_name`
LM_SQS_REGION=`terraform output alertlogic_lm_cloudtrail_target_sqs_region`
##Delete Log Manager CloudTrail deployment
LM_CT_NAME=$NAME-$ENV-CloudTrail
LM_CT_CRED_NAME=$NAME-$ENV-CloudTrail-Cred
cd $DIRECTORY/scripts
printf "\n${RED}### DESTROY ALERTLOGIC LOG SOURCE FOR CLOUDTRAIL${NC}\n"
case $DC in
    DENVER )
        LM_DEFENDER_NAME="defender-us-denver" ;;
    ASHBURN )
        LM_DEFENDER_NAME="defender-us-ashburn" ;;
    NEWPORT )
        LM_DEFENDER_NAME="defender-uk-newport" ;;
    *)
      printf "${RED}Wrong argument for DC=$DC ${NC}\n\n"
      exit 1
esac
python deploy_lm_cloudtrail.py DEL --key $APIKEY --cid $CID --ct $LM_CT_NAME --dc $LM_DEFENDER_NAME
ret=$?
if [ $ret -ne 0 ]; then
  printf "\n${RED}### Exit from script, reason: see message above for details${NC}\n\n"
  exit 1
fi
##Destroy Log Manager resources
cd $DIRECTORY/environment/$ENV/log_manager
terraform destroy -force -var-file=$DIRECTORY/environment/$ENV/log_manager/vars.tfvars -var "cloudtrail_sns_arn=$LM_SNS" -var "cloudtrail_s3=$LM_S3"


#Destroy CloudTrail stuff
printf "\n${RED}### DESTROY CLOUDTRAIL RESOURCES${NC}\n"
cd $DIRECTORY/environment/$ENV/cloudtrail
terraform destroy -force -var-file=$DIRECTORY/environment/$ENV/cloudtrail/vars.tfvars


#destroy IAM stuff
printf "\n${RED}### DESTROY IAM RESOURCE${NC}\n"
cd $DIRECTORY/environment/$ENV/iam
terraform destroy -force -var-file=$DIRECTORY/environment/$ENV/iam/vars.tfvars
