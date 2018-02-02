#!/bin/bash
#Text color
RED='\033[0;33m'
NC='\033[0m'

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
printf "\n${RED}PROJECT DIRECTORY=${NC} $DIRECTORY\n"

#initialize ssh agent for ansible
printf "\n${RED}### INITIALIZE SSH AGENT${NC}\n"
eval `ssh-agent`
ssh-add $DIRECTORY/data/key/ansible-terraform.pem


#TODO create SSH key via terraform
#instead of using the existing SSH key, create a new one from fresh

#deploy IAM stuff
printf "\n${RED}### DEPLOY IAM RESOURCES${NC}\n"
cd $DIRECTORY/environment/$ENV/iam
terraform apply -auto-approve -var-file=$DIRECTORY/environment/$ENV/iam/vars.tfvars

#deploy CloudTrail stuff
printf "\n${RED}### DEPLOY CLOUDTRAIL RESOURCES${NC}\n"
cd $DIRECTORY/environment/$ENV/cloudtrail
terraform apply -auto-approve -var-file=$DIRECTORY/environment/$ENV/cloudtrail/vars.tfvars

#deploy AlertLogic Log Manager for CloudTrail
printf "\n${RED}### DEPLOY ALERTLOGIC LOG MANAGER RESOURCES${NC}\n"
cd $DIRECTORY/environment/$ENV/cloudtrail
LM_SNS=`terraform output cloudtrail_sns_topic`
LM_S3=`terraform output cloudtrail_s3_bucket`
cd $DIRECTORY/environment/$ENV/log_manager
terraform apply -auto-approve -var-file=$DIRECTORY/environment/$ENV/log_manager/vars.tfvars -var "cloudtrail_sns_arn=$LM_SNS" -var "cloudtrail_s3=$LM_S3"
LM_ARN=`terraform output alertlogic_lm_cloudtrail_target_iam_role_arn`
LM_SQS=`terraform output alertlogic_lm_cloudtrail_target_sqs_name`
LM_SQS_REGION=`terraform output alertlogic_lm_cloudtrail_target_sqs_region`
LM_CT_NAME=$NAME-$ENV-CloudTrail
LM_CT_CRED_NAME=$NAME-$ENV-CloudTrail-Cred

cd $DIRECTORY/scripts
printf "\n${RED}### CREATE ALERTLOGIC LOG SOURCE FOR CLOUDTRAIL${NC}\n"
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
python deploy_lm_cloudtrail.py ADD --key $APIKEY --cid $CID --iam $LM_ARN --ext $CID --cred $LM_CT_CRED_NAME --sqs $LM_SQS --reg $LM_SQS_REGION --ct $LM_CT_NAME --dc $LM_DEFENDER_NAME
ret=$?
if [ $ret -ne 0 ]; then
  printf "\n${RED}### Exit from script, reason: see message above for details${NC}\n\n"
  exit 1
fi


cd $DIRECTORY/scripts
printf "\n${RED}### LAUNCH ALERTLOGIC CLOUD DEFENDER DEPLOYMENT${NC}\n"
MODE="CD_LAUNCH"
python deploy_alertlogic.py -profile $PROFILE -s3 $S3 -key $KEY -mode $MODE -u $USER -p $PASS -dc $DC  -cid $CID -name $NAME
ret=$?
if [ $ret -ne 0 ]; then
  printf "\n${RED}### Exit from script, reason: cannot launch Cloud Defender deployment${NC}\n\n"
  exit 1
fi

#deploy Network stuff
printf "\n${RED}### DEPLOY VPC RESOURCES${NC}\n"
cd $DIRECTORY/environment/$ENV/network
terraform apply -auto-approve -var-file=$DIRECTORY/environment/$ENV/network/vars.tfvars
terraform output cloud_insight_scope > $DIRECTORY/environment/$ENV/network/cloud_insight_scope.json


#deploy AlertLogic TMC
printf "\n${RED}### DEPLOY ALERTLOGIC TMC RESOURCES${NC}\n"
cd $DIRECTORY/environment/$ENV/threat_manager
terraform apply -auto-approve -var-file=$DIRECTORY/environment/$ENV/threat_manager/vars.tfvars


#deploy Compute stuff
printf "\n${RED}### DEPLOY COMPUTE RESOURCES${NC}\n"
cd $DIRECTORY/environment/$ENV/compute
terraform apply -auto-approve -var-file=$DIRECTORY/environment/$ENV/compute/vars.tfvars
#build inventory file
terraform output ansible_inventory > $DIRECTORY/ansible/inventories/inventory


#check if AlertLogic TMC is fully ready
printf "\n${RED}### VERIFY IF ALERTLOGIC TMC IS READY${NC}\n"
cd $DIRECTORY/scripts
TIMEOUT="3000"
TMC_EXTERNAL_IP=$( cat $DIRECTORY/environment/$ENV/threat_manager/public_ips.txt )
TMC_INTERNAL_IP=$( cat $DIRECTORY/environment/$ENV/threat_manager/private_ips.txt )
python tmc_is_claimed.py $TMC_EXTERNAL_IP $TIMEOUT
ret=$?
if [ $ret -ne 0 ]; then
  printf "\n${RED}### Exit from script, reason: cannot validate if Threat Manager claimed${NC}\n\n"
  exit 1
fi

printf "\n${RED}### SLEEP 2 MINS TO LET ALERTLOGIC TMC READY${NC}\n"
sleep 120

#run ansible
printf "\n${RED}### START ANSIBLE${NC}\n"
cd $DIRECTORY/ansible
ansible web -i $DIRECTORY/ansible/inventories/inventory -m ping
ansible-playbook -i $DIRECTORY/ansible/inventories/inventory -e "TMC_INTERNAL_IP=$TMC_INTERNAL_IP" $DIRECTORY/ansible/webserver.yaml


#kill ssh-agent
printf "\n${RED}### CLOSE SSH AGENT${NC}\n"
eval `ssh-agent -k`


#launch Cloud Insight without VPC scope
cd $DIRECTORY/scripts
printf "\n${RED}### LAUNCH ALERTLOGIC CLOUD INSIGHT WITHOUT SCOPE${NC}\n"
MODE="CI_LAUNCH"
python deploy_alertlogic.py -profile $PROFILE -s3 $S3 -key $KEY -mode $MODE -u $USER -p $PASS -dc $DC -cid $CID -name $NAME
ret=$?
if [ $ret -ne 0 ]; then
  printf "\n${RED}### Exit from script, reason: cannot launch Cloud Insight deployment${NC}\n\n"
  exit 1
fi

printf "\n${RED}### SLEEP 2 MINS TO LET CLOUD INSIGHT DISCOVERY FINSIHED${NC}\n"
sleep 120

#TODO: modify deploy_aletlogic.py to detect vpc resource
#launch Cloud Insight into VPC
cd $DIRECTORY/scripts
printf "\n${RED}### APPEND VPC TO ALERTLOGIC CLOUD INSIGHT${NC}\n"
MODE="CI_APPEND"
python deploy_alertlogic.py -profile $PROFILE -s3 $S3 -key $KEY -mode $MODE -u $USER -p $PASS -dc $DC -cid $CID -name $NAME -scope $DIRECTORY/environment/$ENV/network/cloud_insight_scope.json -out $DIRECTORY/environment/$ENV/cloud_insight/cloud_insight_sg_id.txt
ret=$?
if [ $ret -ne 0 ]; then
  printf "\n${RED}### Exit from script, reason: cannot launch Cloud Insight deployment${NC}\n\n"
  exit 1
fi

#Update compute security group to allow cloud Insight scans
printf "\n${RED}### MODIFYING SECURITY GROUP TO ALLOW CLOUD INSIGHT SCANS${NC}\n"
cd $DIRECTORY/environment/$ENV/compute
TARGET_SG=`terraform output web_security_group`
cd $DIRECTORY/environment/$ENV/cloud_insight
SOURCE_CI_SG=`cat $DIRECTORY/environment/$ENV/cloud_insight/cloud_insight_sg_id.txt`
terraform apply -auto-approve -var-file=$DIRECTORY/environment/$ENV/cloud_insight/vars.tfvars -var "source_cloud_insight_sg=$SOURCE_CI_SG" -var "target_security_group=$TARGET_SG"



printf "\n${RED}### END OF SCRIPT${NC}\n"
