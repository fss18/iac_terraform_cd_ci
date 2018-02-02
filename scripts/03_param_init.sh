#!/bin/bash
#Text color
RED='\033[0;33m'
NC='\033[0m'

#Get pwd
reldir=`dirname $0`
cd $reldir
cd ../
DIRECTORY=`pwd`
printf "\n${RED}PROJECT DIRECTORY=${NC} $DIRECTORY\n"

function display_help() {
  printf "${RED}*********************************************************************************${NC}\n"
  printf "${RED}Initialize terraform parameters (.tfvars) based on target environment and module ${NC}\n"
  printf "Usage: \n"
  printf "  --env=ENV_NAME --module=MODULE_NAME [key=value]\n"
  printf "\n"
  printf "Enter [key=value] in format like below \n"
  printf "  TF_VAR=VAR_VALUE \n"
  printf "\n"
  printf "where:\n"
  printf "  TF_VAR    : name of the variable in the terraform template\n"
  printf "  VAR_VALUE : value of the variable \n"
  printf "\n"
  printf "Example: \n"
  printf "  --env=Staging --module=iam region=us-east-1 profile=default\n"
  printf "${RED}*********************************************************************************${NC}\n"
}

for i in "$@"
do
  case $i in
      --env=*)
        ENVIRONMENT="${i#*=}"
        shift
        ;;
      --module=*)
        MODULE="${i#*=}"
        shift
        ;;
      -h|--h)
        display_help
        exit
        ;;
      *)
        key="${i%=*}"
        val="${i#*=}"
        keyval=$key
        keyval="$keyval = \"$val\""
        output="${output}${keyval}\n"
        #printf "$output"
        shift
        #printf "$keyval\n"
        #echo $keyval >> $buffer
        ;;

  esac
done

if [[ -z $ENVIRONMENT || -z $MODULE ]];
then
    printf "${RED}MISSING OR INVALID PARAMETERS, SEE BELOW ${NC}\n"
    display_help
    exit 1
fi

printf "\n${RED}Environment =${NC} $ENVIRONMENT"
printf "\n${RED}Module name =${NC} $MODULE"
printf "\n${RED}.tfvars file =${NC} $DIRECTORY/environment/$ENVIRONMENT/$MODULE/vars.tfvars\n\n"

#> $DIRECTORY/environment/$ENVIRONMENT/$MODULE/tfvarfile.tfvars
echo -e $output > $DIRECTORY/environment/$ENVIRONMENT/$MODULE/vars.tfvars
