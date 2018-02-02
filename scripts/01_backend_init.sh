#!/bin/bash
#Text color
RED='\033[0;33m'
NC='\033[0m'

function display_help() {
  printf "${RED}*********************************************************************************${NC}\n"
  printf "${RED}Initialize backend resource to store Terraform State and manage State locks${NC}\n"
  printf "${RED}Required parameters:${NC}\n"
  printf " --profile   AWS Profile name that you stored under ~/.aws/credentials \n"
  printf " --region    Region for the S3 bucket and the DynamodB \n"
  printf " --S3        S3 Bucket Name to store the Terraform State \n"
  printf " --dynamo    DynamoDB table name to manage Terraform State lock \n"
  printf " --cred      Path to your AWS credentials, i.e. ~/.aws/credentials \n"
  printf "${RED}*********************************************************************************${NC}\n"
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
      S3_BUCKET_NAME="$2"
      shift
      shift
      ;;
    --region)
      REGION="$2"
      shift
      shift
      ;;
    --cred)
      CRED_PATH="$2"
      shift
      shift
      ;;
    --dynamo)
      DYNAMO_DB_NAME="$2"
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

#Get pwd
reldir=`dirname $0`
cd $reldir
cd ../
DIRECTORY=`pwd`
ENV="staging"
printf "\n${RED}PROJECT DIRECTORY=${NC} $DIRECTORY\n"

#Initialize backend supporting data
cd $DIRECTORY/backend
terraform init
terraform apply -auto-approve -var "region=$REGION" -var "profile=$PROFILE" -var "cred_file=$CRED_PATH" -var "bucket_name=$S3_BUCKET_NAME" -var "table_name=$DYNAMO_DB_NAME"
