Sample Run
------------
Run this under ./scripts/

**Initialize backend**

    PROFILE="default"
    REGION="us-east-1"
    S3_BUCKET_NAME="my-project-terraform-state"
    DYNAMO_DB_NAME="my-project-terraform-state"
    CRED_PATH="~/.aws/credentials"
    ./01_backend_init.sh --profile $PROFILE --region $REGION --cred $CRED_PATH --S3 $S3_BUCKET_NAME --dynamo $DYNAMO_DB_NAME

**Initialize each environment templates**

    PROFILE="default"
    REGION="us-east-1"
    S3_BUCKET_NAME="my-project-terraform-state"
    DYNAMO_DB_NAME="my-project-terraform-state"
    CRED_PATH="~/.aws/credentials"
    ENVIRONMENT="staging"
    MODULE="iam"
    ./02_environment_init.sh --profile $PROFILE --region $REGION --cred $CRED_PATH --S3 $S3_BUCKET_NAME --dynamo $DYNAMO_DB_NAME --env $ENVIRONMENT --module $MODULE
    MODULE="cloudtrail"
    ./02_environment_init.sh --profile $PROFILE --region $REGION --cred $CRED_PATH --S3 $S3_BUCKET_NAME --dynamo $DYNAMO_DB_NAME --env $ENVIRONMENT --module $MODULE
    MODULE="log_manager"
    ./02_environment_init.sh --profile $PROFILE --region $REGION --cred $CRED_PATH --S3 $S3_BUCKET_NAME --dynamo $DYNAMO_DB_NAME --env $ENVIRONMENT --module $MODULE
    MODULE="compute"
    ./02_environment_init.sh --profile $PROFILE --region $REGION --cred $CRED_PATH --S3 $S3_BUCKET_NAME --dynamo $DYNAMO_DB_NAME --env $ENVIRONMENT --module $MODULE
    MODULE="network"
    ./02_environment_init.sh --profile $PROFILE --region $REGION --cred $CRED_PATH --S3 $S3_BUCKET_NAME --dynamo $DYNAMO_DB_NAME --env $ENVIRONMENT --module $MODULE
    MODULE="cloud_insight"
    ./02_environment_init.sh --profile $PROFILE --region $REGION --cred $CRED_PATH --S3 $S3_BUCKET_NAME --dynamo $DYNAMO_DB_NAME --env $ENVIRONMENT --module $MODULE
    MODULE="threat_manager"
    ./02_environment_init.sh --profile $PROFILE --region $REGION --cred $CRED_PATH --S3 $S3_BUCKET_NAME --dynamo $DYNAMO_DB_NAME --env $ENVIRONMENT --module $MODULE

**Initialize IAM variables**

    ENVIRONMENT="staging"
    MODULE="iam"
    PROFILE="default"
    CRED_PATH="~/.aws/credentials"
    REGION="us-east-1"
    AL_AWS_ACC_ID="ENTER_YOUR_AWS_ACCOUNT_NUMBER"
    AL_CID="ENTER_YOUR_ALERTLOGIC_ACCOUNT_ID"
    PROJECT_NAME="my-project"
    ./03_param_init.sh --env=$ENVIRONMENT --module=$MODULE \
      profile=$PROFILE \
      cred_file=$CRED_PATH \
      region=$REGION \
      alert_logic_aws_account_id=$AL_AWS_ACC_ID \
      alert_logic_external_id=$AL_CID \
      ci_role_name="${PROJECT_NAME}_${ENVIRONMENT}_ci_role" \
      ci_policy_name="${PROJECT_NAME}_${ENVIRONMENT}_ci_policy" \
      cd_role_name="${PROJECT_NAME}_${ENVIRONMENT}_cd_role" \
      cd_policy_name="${PROJECT_NAME}_${ENVIRONMENT}_cd_policy"

**Initialize CloudTrail variables**

    ENVIRONMENT="staging"
    MODULE="cloudtrail"
    PROFILE="default"
    CRED_PATH="~/.aws/credentials"
    REGION="us-east-1"
    PROJECT_NAME="my-project"
    SNS_TOPIC_NAME="${PROJECT_NAME}_${ENVIRONMENT}_CT_SNS"
    CT_BUCKET_NAME="${PROJECT_NAME}-${ENVIRONMENT}-cloudtrail"
    CT_NAME="AAA-${PROJECT_NAME}-${ENVIRONMENT}"
    FORCE_DELETE_BUCKET="true"
    ./03_param_init.sh --env=$ENVIRONMENT --module=$MODULE \
      profile=$PROFILE \
      cred_file=$CRED_PATH \
      region=$REGION \
      cloudtrail_sns_topic=$SNS_TOPIC_NAME \
      cloudtrail_bucket_name=$CT_BUCKET_NAME \
      cloudtrail_name=$CT_NAME \
      force_delete_bucket=$FORCE_DELETE_BUCKET

**Initialize Log Manager variables**

    ENVIRONMENT="staging"
    PROJECT_NAME="my-project"
    MODULE="log_manager"
    PROFILE="default"
    CRED_PATH="~/.aws/credentials"
    REGION="us-east-1"
    AL_AWS_LM_ACC_ID="239734009475"
    AL_CID="ENTER_YOUR_ALERTLOGIC_ACCOUNT_ID"
    LM_IAM_ROLE_NAME="${PROJECT_NAME}_${ENVIRONMENT}-LM-CloudTrail"
    LM_CLOUDTRAIL_SNS=""
    LM_CLOUDTRAIL_S3=""
    LM_CLOUDTRAIL_SQS="${PROJECT_NAME}_${ENVIRONMENT}-LM-CloudTrail-SQS"
    ./03_param_init.sh --env=$ENVIRONMENT --module=$MODULE \
      profile=$PROFILE \
      cred_file=$CRED_PATH \
      region=$REGION \
      alert_logic_lm_aws_account_id=$AL_AWS_LM_ACC_ID \
      alert_logic_external_id=$AL_CID \
      cloudtrail_role_name=$LM_IAM_ROLE_NAME \
      cloudtrail_sns_arn=$LM_CLOUDTRAIL_SNS \
      cloudtrail_s3=$LM_CLOUDTRAIL_S3 \
      cloudtrail_sqs_name=$LM_CLOUDTRAIL_SQS


**Initialize Network variables**
    
    ENVIRONMENT="staging"
    MODULE="network"
    PROFILE="default"
    VPC_NAME="my-project_vpc"
    VPC_CIDR="10.10.0.0/16"
    PUBLIC_SUBNET_CIDR="10.10.1.0/24"
    PRIVATE_SUBNET_CIDR="10.10.2.0/24"
    AZ="us-east-1a"
    ./03_param_init.sh --env=$ENVIRONMENT --module=$MODULE \
      profile=$PROFILE \
      cred_file=$CRED_PATH \
      region=$REGION \
      vpc_name=$VPC_NAME \
      vpc_cidr=$VPC_CIDR \
      public_subnet_cidr=$PUBLIC_SUBNET_CIDR \
      private_subnet_cidr=$PRIVATE_SUBNET_CIDR \
      availability_zone=$AZ

**Initialize Compute variables**

    ENVIRONMENT="staging"
    MODULE="compute"
    PROFILE="default"
    CRED_PATH="~/.aws/credentials"
    REGION="us-east-1"
    KEY_NAME="ansible-terraform"
    INSTANCE_TYPE="t2.micro"
    INSTANCE_COUNT="2"
    PRIVATE_KEY_PATH="/PATH_TO_REPO/data/key/ansible-terraform.pem"
    VPC_STATE_BUCKET="my-project-terraform-state"
    VPC_STATE_KEY="state/$ENVIRONMENT/network"
    ./03_param_init.sh --env=$ENVIRONMENT --module=$MODULE \
      profile=$PROFILE \
      cred_file=$CRED_PATH \
      region=$REGION \
      vpc_state_bucket=$VPC_STATE_BUCKET \
      vpc_state_key=$VPC_STATE_KEY \
      key_name=$KEY_NAME \
      instance_type=$INSTANCE_TYPE \
      instance_count=$INSTANCE_COUNT \
      private_key_path=$PRIVATE_KEY_PATH

**Initialize Cloud Insight  variables**

    ENVIRONMENT="staging"
    MODULE="cloud_insight"
    PROFILE="default"
    CRED_PATH="~/.aws/credentials"
    REGION="us-east-1"
    VPC_STATE_BUCKET="my-project-terraform-state"
    VPC_STATE_KEY="state/$ENVIRONMENT/cloud_insight"
    SOURCE_SG=""
    TARGET_SG=""
    ./03_param_init.sh --env=$ENVIRONMENT --module=$MODULE \
      profile=$PROFILE \
      cred_file=$CRED_PATH \
      region=$REGION \
      vpc_state_bucket=$VPC_STATE_BUCKET \
      vpc_state_key=$VPC_STATE_KEY \
      source_cloud_insight_sg=$SOURCE_SG \
      target_security_group=$TARGET_SG

**Initialize Threat Manager  variables**

    ENVIRONMENT="staging"
    MODULE="threat_manager"
    PROFILE="default"
    CRED_PATH="~/.aws/credentials"
    REGION="us-east-1"
    TMC_INSTANCE_TYPE="t2.medium"
    TMC_TAG_NAME="alert_logic_tmc"
    CLAIM_CIDR="0.0.0.0/0"
    VPC_STATE_BUCKET="my-project-terraform-state"
    VPC_STATE_KEY="state/$ENVIRONMENT/network"
    ./03_param_init.sh --env=$ENVIRONMENT --module=$MODULE \
      profile=$PROFILE \
      cred_file=$CRED_PATH \
      region=$REGION \
      vpc_state_bucket=$VPC_STATE_BUCKET \
      vpc_state_key=$VPC_STATE_KEY \
      instance_type=$TMC_INSTANCE_TYPE \
      tag_name=$TMC_TAG_NAME \
      claimCIDR=$CLAIM_CIDR

**Deploy / Launch the infrastructure**

    PROFILE="default"
    S3_BUCKET_NAME="my-project-terraform-state"
    USER="FIRST.LAST@COMPANY.com"
    PASS="MY_CLOUD_INSIGHT_PASSWORD"
    APIKEY="MY_CLOUD_DEFENDER_USER_API_KEY"
    DC="ASHBURN"
    CID="ENTER_YOUR_ALERTLOGIC_ACCOUNT_ID"
    PROJECT_NAME="my-project"
    ENVIRONMENT="staging"
    ./04_deploy.sh --profile $PROFILE --S3 $S3_BUCKET_NAME --user $USER --pass $PASS --apikey $APIKEY --dc $DC --cid $CID --name $PROJECT_NAME --env $ENVIRONMENT


**Destroy the infrastructure**

    PROFILE="default"
    S3_BUCKET_NAME="my-project-terraform-state"
    USER="FIRST.LAST@COMPANY.com"
    PASS="MY_CLOUD_INSIGHT_PASSWORD"
    APIKEY="MY_CLOUD_DEFENDER_USER_API_KEY"
    DC="ASHBURN"
    CID="ENTER_YOUR_ALERTLOGIC_ACCOUNT_ID"
    PROJECT_NAME="my-project"
    ENVIRONMENT="staging"
    ./05_destroy.sh --profile $PROFILE --S3 $S3_BUCKET_NAME --user $USER --pass $PASS --apikey $APIKEY --dc $DC --cid $CID --name $PROJECT_NAME --env $ENVIRONMENT
