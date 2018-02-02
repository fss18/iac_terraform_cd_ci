import boto3
import sys
import json
import requests
import time
import copy
from sys import argv
import jsonschema
from jsonschema import validate

#suppres warning for certificate
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

#exit code standard:
#0 = OK
#1 = argument parser issue
#2 = environment issue such as invalid environment id, invalid password, or invalid scope
#3 = timeout

#Get IAM ARN from Remote State based on search criteria
def get_iam_arn(profile, bucket_name, object_key, search_value):
    role_arn = ""
    session = boto3.Session(profile_name=profile)
    s3resource = session.resource('s3')
    bucket = s3resource.Bucket(bucket_name)
    obj = bucket.Object(object_key)

    print('Bucket name: {}'.format(bucket.name))
    print('Object key: {}'.format(obj.key))
    print('Object content length: {}'.format(obj.content_length))
    print('Object last modified: {}'.format(obj.last_modified))
    print('Search criteria: {}'.format(search_value))

    obj_data = json.load(obj.get()['Body'])
    for tfmodule in obj_data["modules"]:
        if tfmodule["outputs"]:
            if search_value in tfmodule["outputs"]:
                role_arn = tfmodule["outputs"][search_value]["value"]

    if role_arn != "":
        print('IAM Role ARN found : {}'.format(role_arn))
        return role_arn
    else:
        print ("IAM Role ARN not found")
        return "N/A"

def authenticate(user, paswd, yarp):
    #Authenticate with CI yarp to get token
    url = yarp
    user = user
    password = paswd
    r = requests.post('https://{0}/aims/v1/authenticate'.format(url), auth=(user, password), verify=False)
    if r.status_code != 200:
        sys.exit("Unable to authenticate %s" % (r.status_code))
    account_id = json.loads(r.text)['authentication']['user']['account_id']
    token = r.json()['authentication']['token']
    return token

def get_source_cred(token, target_cid, arn, insight_dc):
    api_endpoint = "https://api.cloudinsight" + insight_dc + "/sources/v1/" + target_cid + "/credentials?credential.type=iam_role"
    request = requests.get(api_endpoint, headers={'x-aims-auth-token': token}, verify=False)
    results = json.loads(request.text)

    for credential in results["credentials"]:
        if credential["credential"]["iam_role"]["arn"] == arn:
            return credential
            break

def prep_credentials(iam_arn, iam_ext_id, cred_name):
    #Setup dictionary for credentials payload
    RESULT = {}
    RESULT['credential']  = {}
    RESULT['credential']['name'] = str(cred_name)
    RESULT['credential']['type'] = "iam_role"
    RESULT['credential']['iam_role'] = {}
    RESULT['credential']['iam_role']['arn'] = str(iam_arn)
    RESULT['credential']['iam_role']['external_id'] = str(iam_ext_id)
    return RESULT

def post_credentials(token, payload, target_cid, insight_dc):
    #Call API with method POST to create new credentials, return the credential ID
    API_ENDPOINT = "https://api.cloudinsight" + insight_dc + "/sources/v1/" + target_cid + "/credentials/"
    REQUEST = requests.post(API_ENDPOINT, headers={'x-aims-auth-token': token}, verify=False, data=payload)
    print ("Create Credentials Status : " + str(REQUEST.status_code), str(REQUEST.reason))
    if REQUEST.status_code == 201:
        RESULT = json.loads(REQUEST.text)
    else:
        RESULT = None
    return RESULT

def get_source_environment(token, target_cid, cred_id, project_name, insight_dc):
    api_endpoint = "https://api.cloudinsight" + insight_dc + "/sources/v1/" + target_cid + "/sources?source.type=environment"
    request = requests.get(api_endpoint, headers={'x-aims-auth-token': token}, verify=False)
    results = json.loads(request.text)
    for source in results["sources"]:
        if source["source"]["config"]["aws"]["credential"]["id"] == cred_id:
            if source["source"]["name"] == project_name:
                return source
                break

def prep_ci_source_environment(aws_account, cred_id, environment_name, scope_data):
    #Setup dictionary for environment payload
    RESULT = {}
    RESULT['source']  = {}
    RESULT['source']['config'] = {}
    RESULT['source']['config']['aws'] = {}
    RESULT['source']['config']['aws']['account_id'] = aws_account
    RESULT['source']['config']['aws']['discover'] = True
    RESULT['source']['config']['aws']['scan'] = True
    RESULT['source']['config']['aws']['credential'] = {}
    RESULT['source']['config']['aws']['credential']['id'] = cred_id

    if (scope_data["include"] or scope_data["exclude"]):
        RESULT['source']['config']['aws']['scope'] = {}
        RESULT['source']['config']['aws']['scope']['include'] = scope_data["include"]
        RESULT['source']['config']['aws']['scope']['exclude'] = scope_data["exclude"]

    RESULT['source']['config']['collection_method'] = "api"
    RESULT['source']['config']['collection_type'] = "aws"
    RESULT['source']['enabled'] = True
    RESULT['source']['name'] = environment_name
    RESULT['source']['product_type'] = "outcomes"
    RESULT['source']['tags'] = []
    RESULT['source']['type'] = "environment"
    return RESULT

def prep_cd_source_environment(aws_account, cred_id, environment_name, defender_location):
	#Setup dictionary for environment payload
	RESULT = {}
	RESULT['source']  = {}
	RESULT['source']['config'] = {}
	RESULT['source']['config']['aws'] = {}
	RESULT['source']['config']['aws']['account_id'] = aws_account
	RESULT['source']['config']['aws']['defender_location_id'] = defender_location
	RESULT['source']['config']['aws']['defender_support'] = True
	RESULT['source']['config']['aws']['discover'] = True
	RESULT['source']['config']['aws']['scan'] = False
	RESULT['source']['config']['aws']['credential'] = {}
	RESULT['source']['config']['aws']['credential']['id'] = cred_id
	RESULT['source']['config']['collection_method'] = "api"
	RESULT['source']['config']['collection_type'] = "aws"
	RESULT['source']['enabled'] = True
	RESULT['source']['name'] = environment_name
	RESULT['source']['product_type'] = "outcomes"
	RESULT['source']['tags'] = []
	RESULT['source']['type'] = "environment"
	return RESULT

def post_source_environment(token, payload, target_cid, insight_dc):
    #Call API with method POST to create new environment
    API_ENDPOINT = "https://api.cloudinsight" + insight_dc + "/sources/v1/" + target_cid + "/sources/"
    REQUEST = requests.post(API_ENDPOINT, headers={'x-aims-auth-token': token}, verify=False, data=payload)
    print ("Create Environment Status : " + str(REQUEST.status_code), str(REQUEST.reason))
    if REQUEST.status_code == 201:
        RESULT = json.loads(REQUEST.text)
    else:
        RESULT = None
    return RESULT

def del_source_environment(token, target_env, target_cid, insight_dc):
	#Delete the specified environment by environment ID and CID
	API_ENDPOINT = "https://api.cloudinsight" + insight_dc + "/sources/v1/" + target_cid + "/sources/" + target_env
	REQUEST = requests.delete(API_ENDPOINT, headers={'x-aims-auth-token': token}, verify=False)
	print ("Delete Environment Status : " + str(REQUEST.status_code), str(REQUEST.reason))

def del_source_credentials(token, target_cred, target_cid, insight_dc):
	#Delete the specified credentials by credentials ID and CID
	API_ENDPOINT = "https://api.cloudinsight" + insight_dc + "/sources/v1/" + target_cid + "/credentials/" + target_cred
	REQUEST = requests.delete(API_ENDPOINT, headers={'x-aims-auth-token': token}, verify=False)
	print ("Delete Credentials Status : " + str(REQUEST.status_code), str(REQUEST.reason))

def put_source_environment(token, payload, target_cid, target_env_id, insight_dc):
	#Call API with method POST to create new environment
	API_ENDPOINT = "https://api.cloudinsight" + insight_dc + "/sources/v1/" + target_cid + "/sources/" + target_env_id
	REQUEST = requests.put(API_ENDPOINT, headers={'x-aims-auth-token': token}, verify=False, data=payload)
	print ("Update Environment Status : " + str(REQUEST.status_code), str(REQUEST.reason))
	if REQUEST.status_code == 201:
		RESULT = json.loads(REQUEST.text)
	else:
		RESULT = {}
		RESULT['source'] = {}
		RESULT['source']['id'] = "n/a"
	return RESULT

def get_launcher_status(token, target_env, target_cid, insight_dc):
	#Check if Launcher is completed
	API_ENDPOINT = "https://api.cloudinsight" + insight_dc + "/launcher/v1/" + target_cid + "/environments/" + target_env
	REQUEST = requests.get(API_ENDPOINT, headers={'x-aims-auth-token': token}, verify=False)

	print ("Retrieving Environment launch status : " + str(REQUEST.status_code), str(REQUEST.reason))
	if REQUEST.status_code == 200:
		RESULT = json.loads(REQUEST.text)
	else:
		RESULT = {}
		RESULT['scope'] = "n/a"

	return RESULT

def get_launcher_data(token, target_env, target_cid, insight_dc):
	#Get all AWS related resource deployed by Cloud Insight
	API_ENDPOINT = "https://api.cloudinsight" + insight_dc + "/launcher/v1/" + target_cid + "/" + target_env + "/resources"
	REQUEST = requests.get(API_ENDPOINT, headers={'x-aims-auth-token': token}, verify=False)

	print ("Retrieving Environment resources data : " + str(REQUEST.status_code), str(REQUEST.reason))
	if REQUEST.status_code == 200:
		RESULT = json.loads(REQUEST.text)
	else:
		RESULT = {}
		RESULT['environment_id'] = "n/a"

	return RESULT

def launcher_wait_state(token, target_env, target_cid, mode, timeout, output_path, insight_dc):
	#Wait for launcher to be fully deployed
	global EXIT_CODE
	TIMEOUT_COUNTER=10

	print ("\n### Start of Check Launcher Status ###")

	#give sufficient time for backend to update Launcher status
	time.sleep(10)
	LAUNCHER_STATUS = True

	while True:
		if mode == "ADD" or mode == "DISC" or mode =="APD" or mode =="RMV":
			#Get Launcher Status and check for each region / VPC
			LAUNCHER_RESULT = get_launcher_status(token, target_env, target_cid, insight_dc)
			if LAUNCHER_RESULT["scope"] != "n/a":
				LAUNCHER_FLAG = True

				for LAUNCHER_REGION in LAUNCHER_RESULT["scope"]:
					print ("Region : " + str(LAUNCHER_REGION["key"])  + " status : " + str(LAUNCHER_REGION["protection_state"]) )
					if LAUNCHER_REGION["protection_state"] == "failed":
						#this can occur due to launcher can't see the VPC yet, throw this back
						LAUNCHER_STATUS = False
						LAUNCHER_FLAG = False

					elif LAUNCHER_REGION["protection_state"] != "completed" and LAUNCHER_REGION["protection_state"] != "removed":
						LAUNCHER_STATUS = True
						LAUNCHER_FLAG = False

				#this indicate a failure in launcher that needs to be returned
				if LAUNCHER_STATUS == False:
					print ("\n### One of the launcher failed - returning to retry launch ###")
					break
				elif LAUNCHER_FLAG == True:
					print ("\n### Launcher Completed Successfully ###")
					LAUNCHER_RETRY = 5
					LAUNCHER_STATUS = True

					while LAUNCHER_RETRY > 0:
						LAUNCHER_DATA = get_launcher_data(token, target_env, target_cid, insight_dc)
						if LAUNCHER_DATA["environment_id"] != "n/a":

							print ("\n### Successfully retrieve Launcher data ###")
							SG_OUTPUT_FILE = open(output_path,'w')
							for LAUNCHER_VPC in LAUNCHER_DATA["vpcs"]:
								print ("Region: " + str(LAUNCHER_VPC["region"]))
								print ("VPC: " + str(LAUNCHER_VPC["vpc_key"]))
								print ("SG: " + str(LAUNCHER_VPC["security_group"]["resource_id"]))
								print ("\n")
								SG_OUTPUT_FILE.write(str(LAUNCHER_VPC["security_group"]["resource_id"]))
							SG_OUTPUT_FILE.close()
							LAUNCHER_RETRY = 0
						else:
							print ("\n### Failed to retrieve Launcher Data, see response code + reason above, retrying in 10 seconds ###")
							time.sleep(10)
							LAUNCHER_RETRY = LAUNCHER_RETRY -1
							if LAUNCHER_RETRY <= 0: EXIT_CODE=3

					break

			else:
				#Launcher did not execute for any reason
				LAUNCHER_FLAG = False
				LAUNCHER_STATUS = False
				print ("\n### One of the launcher failed - returning to retry launch ###")
				break;

		elif mode == "DEL":
			#Get Launcher Status
			LAUNCHER_RESULT = get_launcher_status(token, target_env, target_cid, insight_dc)

			if LAUNCHER_RESULT["scope"] == "n/a":
				print ("\n### Launcher Deleted Successfully ###")
				break;

		#Sleep for 10 seconds
		timeout = timeout - TIMEOUT_COUNTER
		if timeout < 0:
			print ("\n### Script timeout exceeded ###")
			EXIT_CODE=3
			break;

		time.sleep(TIMEOUT_COUNTER)

	print ("### End of Check Launcher Status ###\n")
	return LAUNCHER_STATUS

# Using jsonschema Python library. (http://json-schema.org)
# Schema for scope in Cloud Insight source
schema = {
    "$schema": "http://json-schema.org/draft-04/schema#",
    "title": "Cloud Insight Scope",
    "description": "Schema for CI Scope",
    "type": "object",
    "properties": {
        "include": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "type" : {
                        "type": "string",
                        "enum": [ "vpc", "region", "subnet"]
                    },
                    "key": {
                        "type": "string",
                        "pattern": "^/aws/[^/]+(/[^/]+)*$"
                    }
                },
                "required": ["type", "key"]
            },
            "minItems": 1,
            "uniqueItems": True
        },
        "exclude": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "type" : {
                        "type": "string",
                        "enum": [ "vpc", "region", "subnet"]
                    },
                    "key": {
                        "type": "string",
                        "pattern": "^/aws/[^/]+(/[^/]+)*$"
                    }
                },
                "required": ["type", "key"]
            }
        }
    },
    "required": ["include"]
}

def scope_schema_check(json_data):
	#print("Validate the scope using the following schema:")
	#print(json.dumps(schema, indent=4))

	# The data to be validated:
	data =[]
	data.append(json_data)

	print("\nRaw input data:")
	print(json.dumps(data, indent=4))

	print("Validation input data using the schema:")
	for idx, item in enumerate(data):
	    try:
	        validate(item, schema)
	        sys.stdout.write("Record #{}: OK\n".format(idx))
	        return True
	    except jsonschema.exceptions.ValidationError as ve:
	        sys.stderr.write("Record #{}: ERROR\n".format(idx))
	        sys.stderr.write(str(ve) + "\n")
	        return False

def open_input_file(file_path):
	try:
		with open(file_path) as input_data:
			RESULT = json.load(input_data)
			return RESULT
	except IOError:
		print ("### File not found : " + str(file_path) + " - scope will be skipped ###")
		return False

def append_scope(source_scope, new_scope, scope_limit):

	#transform Dictionary to List
	original_vpc_scope = change_scope_to_list(source_scope, "vpc")
	new_vpc_scope = change_scope_to_list(new_scope, "vpc")

	#build set for VPC scope by combining existing and new VPC
	final_vpc_scope = original_vpc_scope + new_vpc_scope
	final_vpc_scope = set(final_vpc_scope)

	#transform Dictionary to List
	original_region_scope = change_scope_to_list(source_scope, "region")
	new_region_scope = change_scope_to_list(new_scope, "region")

	#build set for Region scope by combining existing and new region
	final_region_scope = original_region_scope + new_region_scope
	final_region_scope = set(final_region_scope)

	#Rebuild the scope to match the schema
	rebuild_scope = {}
	rebuild_scope[scope_limit] = []

	#add all unique vpc
	for item in final_vpc_scope:
		new_item = {}
		new_item["type"] = "vpc"
		new_item["key"] = item
		rebuild_scope[scope_limit].append(new_item)

	#add all unique regions
	for item in final_region_scope:
		new_item = {}
		new_item["type"] = "region"
		new_item["key"] = item
		rebuild_scope[scope_limit].append(new_item)

	return rebuild_scope

def filter_scope(source_scope, new_scope, scope_type, mode):
	source_scope = change_scope_to_list(source_scope, scope_type)
	new_scope = change_scope_to_list(new_scope, scope_type)

	#find the resultant changes
	if mode == "APD" or mode == "DISC":
		difference_scope = set(new_scope) - set(source_scope)

	elif mode == "RMV":
		difference_scope = set(source_scope) - (set(source_scope) - set(new_scope))

	elif mode == "ADD":
		difference_scope = set(new_scope + source_scope)

	return difference_scope

#Get script arguments
def get_opts(argv):
    opts = {}
    while argv:
        if argv[0][0] == '-':
            opts[argv[0]] = argv[1]
        argv = argv[1:]
    return opts

#Parse all arguments
def parse_args(argv):
    global CID, OPERATIONS, SCRIPT_TIMEOUT, PROJECT_NAME, STATE_BUCKET, STATE_KEY, AWS_PROFILE, AL_ACCESS_KEY, AL_SECRET_KEY, ALERT_LOGIC_CI_DC, ALERT_LOGIC_CD_DC, ALERT_LOGIC_DEFENDER_LOCATION, TARGET_SCOPE, OUTPUT_PATH

    if "-s3" in myargs:
        STATE_BUCKET = myargs["-s3"]
    else:
        print ("Argument -s3 is required for Terraform Remote State S3 bucket")
        sys.exit()

    if "-key" in myargs:
        STATE_KEY = myargs["-key"]
    else:
        print ("Argument -key is required for Terraform Remote State Key / Path")
        sys.exit()
    if "-profile" in myargs:
        AWS_PROFILE = myargs["-profile"]
    else:
        print ("Argument -profile is required, enter the ~/.aws/credentials profile name")
        sys.exit()

    if "-u" in myargs:
        AL_ACCESS_KEY = myargs["-u"]
    else:
        print ("Argument -u is required, enter either user name or access key")
        sys.exit()

    if "-p" in myargs:
        AL_SECRET_KEY = myargs["-p"]
    else:
        print ("Argument -p is required, enter either password or secret key")
        sys.exit()

    if "-cid" in myargs:
        CID = myargs["-cid"]
    else:
        print ("Argument -cid is required for Customer ID")
        sys.exit()

    if "-name" in myargs:
        PROJECT_NAME = myargs["-name"]
    else:
        print ("Argument -name is required for title of the project, this will be used as reference name in Cloud Insight")
        sys.exit()

    if "-timeout" in myargs:
        SCRIPT_TIMEOUT = myargs["-timeout"]
    else:
        SCRIPT_TIMEOUT = 300

    if "-out" in myargs:
        OUTPUT_PATH = myargs["-out"]
    else:
        OUTPUT_PATH = "./cloud_insight_sg_id.txt"

    if "-dc" in myargs:
        if myargs["-dc"] == "DENVER":
            ALERT_LOGIC_CI_DC = ".alertlogic.com"
            ALERT_LOGIC_CD_DC = ".alertlogic.net"
            ALERT_LOGIC_DEFENDER_LOCATION = "defender-us-denver"

        elif myargs["-dc"] == "ASHBURN":
            ALERT_LOGIC_CI_DC = ".alertlogic.com"
            ALERT_LOGIC_CD_DC = ".alertlogic.com"
            ALERT_LOGIC_DEFENDER_LOCATION = "defender-us-ashburn"

        elif myargs["-dc"] == "NEWPORT":
            ALERT_LOGIC_CI_DC = ".alertlogic.co.uk"
            ALERT_LOGIC_CD_DC = ".alertlogic.co.uk"
            ALERT_LOGIC_DEFENDER_LOCATION = "defender-uk-newport"
        else:
            print ("Invalid value for argument -dc, accepted value: DENVER, ASHBURN, NEWPORT")
    else:
        print ("Argument -dc is required, value accepted: DENVER, ASHBURN, NEWPORT")
        sys.exit()

    if "-mode" in myargs:
        OPERATIONS = myargs["-mode"]
        if OPERATIONS == "CI_LAUNCH":
            print ("Operation mode = Launch Cloud Insight Environment")
        elif OPERATIONS == "CD_LAUNCH":
            print ("Operation mode = Launch Cloud Defender Environment")
        elif OPERATIONS == "CI_DESTROY":
            print ("Operation mode = Destroy Cloud Insight Environment")
        elif OPERATIONS == "CD_DESTROY":
            print ("Operation mode = Destroy Cloud Defender Environment")
        elif OPERATIONS == "CI_APPEND":
            print ("Operation mode = Append Scope to Cloud Insight Environment")
        else:
            print ("Invalid value for argument -mode, accepted value: CI_LAUNCH, CD_LAUNCH")
    else:
        print ("Argument -mode is required, accepted value CI_LAUNCH, CD_LAUNCH")
        sys.exit()

    if "-scope" in myargs:
        TARGET_SCOPE = myargs["-scope"]
    else:
        if OPERATIONS == "CI_APPEND":
            print ("Please provide scope. Argumen -scope is required, accepted value: path to JSON scope file")
            sys.exit()


if __name__ == "__main__":
    myargs = get_opts(argv)
    parse_args(myargs)

    #Authenticate with Cloud Insight and retrieve token
    try:
        TOKEN = str(authenticate(AL_ACCESS_KEY, AL_SECRET_KEY, "api.cloudinsight" + ALERT_LOGIC_CI_DC))
        print ("Insight Authentication Success")
    except Exception, e:
        print (e)
        print ("### Cannot Authenticate - check user name or password ###\n")
        EXIT_CODE = 2
        sys.exit(EXIT_CODE)

    if OPERATIONS == "CI_LAUNCH" or OPERATIONS == "CD_LAUNCH":
        #Get the IAM role arn for cloud Insight
        if OPERATIONS == "CI_LAUNCH":
            ARN = get_iam_arn(AWS_PROFILE, STATE_BUCKET, STATE_KEY, "alertlogic_cloud_insight_target_iam_role_arn")
        elif OPERATIONS == "CD_LAUNCH":
            ARN = get_iam_arn(AWS_PROFILE, STATE_BUCKET, STATE_KEY, "alertlogic_cloud_defender_target_iam_role_arn")

        if ARN != "N/A":
            #Validate if the credentials exist, if not, create one first
            print ("Check or Create Credentials for IAM ARN: {}".format(ARN))
            CRED = get_source_cred(TOKEN, CID, ARN, ALERT_LOGIC_CI_DC)
            if CRED != None:
                print ("Credential found with ID: {}".format(CRED["credential"]["id"]))
            else:
                if OPERATIONS == "CI_LAUNCH":
                    CRED_PAYLOAD = prep_credentials(ARN, CID, PROJECT_NAME + "_ci_role")
                elif OPERATIONS == "CD_LAUNCH":
                    CRED_PAYLOAD = prep_credentials(ARN, CID, PROJECT_NAME + "_cd_role")

                CRED = post_credentials(TOKEN, str(json.dumps(CRED_PAYLOAD, indent=4)), CID, ALERT_LOGIC_CI_DC)
                if CRED != None:
                    print ("New Credential created with ID: {}".format(CRED["credential"]["id"]))
                else:
                    EXIT_CODE = 2
                    sys.exit(EXIT_CODE)

            #Validate if the environment exist, if not, create new environment
            print ("Check or Create Deployment with name: {}".format(PROJECT_NAME))
            ENV = get_source_environment(TOKEN, CID, CRED["credential"]["id"], PROJECT_NAME, ALERT_LOGIC_CI_DC)
            if ENV != None:
                print ("Deployment found with ID: {}".format(ENV["source"]["id"]))
            else:
                if OPERATIONS == "CI_LAUNCH":
                    INPUT_SCOPE = {}
                    INPUT_SCOPE["include"] = []
                    INPUT_SCOPE["exclude"] = []
                    ENV_PAYLOAD = prep_ci_source_environment(str(ARN).split(":")[4], CRED["credential"]["id"], PROJECT_NAME, INPUT_SCOPE)
                elif OPERATIONS == "CD_LAUNCH":
                    ENV_PAYLOAD = prep_cd_source_environment(str(ARN).split(":")[4], CRED["credential"]["id"], PROJECT_NAME, ALERT_LOGIC_DEFENDER_LOCATION)

                ENV = post_source_environment(TOKEN, str(json.dumps(ENV_PAYLOAD, indent=4)), CID, ALERT_LOGIC_CI_DC)
                if ENV != None:
                    print ("New Deployment created with ID: {}".format(ENV["source"]["id"]))
                else:
                    EXIT_CODE = 2
                    sys.exit(EXIT_CODE)
        else:
            print ("Unable to resume Deployment launch, IAM role not found")

    elif OPERATIONS == "CD_DESTROY" or OPERATIONS == "CI_DESTROY":
        #Get the IAM role arn for cloud Insight
        if OPERATIONS == "CI_DESTROY":
            ARN = get_iam_arn(AWS_PROFILE, STATE_BUCKET, STATE_KEY, "alertlogic_cloud_insight_target_iam_role_arn")
        elif OPERATIONS == "CD_DESTROY":
            ARN = get_iam_arn(AWS_PROFILE, STATE_BUCKET, STATE_KEY, "alertlogic_cloud_defender_target_iam_role_arn")

        if ARN != "N/A":
            #Validate if the credentials exist
            print ("Check and Delete Credentials for IAM ARN: {}".format(ARN))
            CRED = get_source_cred(TOKEN, CID, ARN, ALERT_LOGIC_CI_DC)
            if CRED != None:
                print ("Credential found with ID: {}".format(CRED["credential"]["id"]))
                #Validate if the environment exist
                print ("Check and Delete Deployment with name: {}".format(PROJECT_NAME))
                ENV = get_source_environment(TOKEN, CID, CRED["credential"]["id"], PROJECT_NAME, ALERT_LOGIC_CI_DC)
                if ENV != None:
                    print ("Deployment found with ID: {}".format(ENV["source"]["id"]))
                    #Delete the environment
                    del_source_environment(TOKEN, ENV["source"]["id"], CID, ALERT_LOGIC_CI_DC)
                    if OPERATIONS == "CI_DESTROY":
                        #Check and wait until launcher completed
                        launcher_wait_state(TOKEN, ENV["source"]["id"], CID, "DEL", SCRIPT_TIMEOUT, OUTPUT_PATH, ALERT_LOGIC_CI_DC)
                    #Delete the credentials associated with that environment
                    del_source_credentials(TOKEN, CRED["credential"]["id"], CID, ALERT_LOGIC_CI_DC)
                else:
                    print ("No Deployment found - skipping Destroy")

            else:
                print ("No Credentials found - skipping Destroy")

    elif OPERATIONS == "CI_APPEND":
        #Get the IAM role arn for cloud Insight
        ARN = get_iam_arn(AWS_PROFILE, STATE_BUCKET, STATE_KEY, "alertlogic_cloud_insight_target_iam_role_arn")
        if ARN != "N/A":
            #Validate if the credentials exist
            print ("Check and Delete Credentials for IAM ARN: {}".format(ARN))
            CRED = get_source_cred(TOKEN, CID, ARN, ALERT_LOGIC_CI_DC)
            if CRED != None:
                print ("Credential found with ID: {}".format(CRED["credential"]["id"]))
                #Validate if the environment exist
                print ("Check Deployment status with name: {}".format(PROJECT_NAME))
                SOURCE_RESULT = get_source_environment(TOKEN, CID, CRED["credential"]["id"], PROJECT_NAME, ALERT_LOGIC_CI_DC)
                if SOURCE_RESULT != None:
                    print ("Deployment found with ID: {}".format(SOURCE_RESULT["source"]["id"]))
                    print ("\n### Reading input file ... ###")
                    INPUT_SCOPE = []
                    INPUT_SCOPE = open_input_file(TARGET_SCOPE)

                    if INPUT_SCOPE != False:
                        #Update the source environment based on env ID and new payload
                        ENV_PAYLOAD = copy.deepcopy(SOURCE_RESULT)
                        #clean up fields that is not required
                        if ENV_PAYLOAD["source"].has_key("created"): del ENV_PAYLOAD["source"]["created"]
                        if ENV_PAYLOAD["source"].has_key("modified"): del ENV_PAYLOAD["source"]["modified"]
                        #create the first scope
                        ENV_PAYLOAD["source"]["config"]["aws"]["scope"] = INPUT_SCOPE
                        print ("\nFinal Scope:")
                        print (json.dumps(INPUT_SCOPE,indent=4))
                        ENV_RESULT = put_source_environment(TOKEN, str(json.dumps(ENV_PAYLOAD, indent=4)), CID, SOURCE_RESULT["source"]["id"], ALERT_LOGIC_CI_DC)
                        ENV_ID = str(ENV_RESULT['source']['id'])
                        if ENV_ID != "n/a":
                            print ("Env ID : " + ENV_ID)
                            print ("\n### Cloud Insight Environment created / updated successfully ###")
                            launcher_wait_state(TOKEN, ENV_ID, CID, "APD", SCRIPT_TIMEOUT, OUTPUT_PATH, ALERT_LOGIC_CI_DC)
                else:
                    print ("No Deployment found - skipping Append")
            else:
                print ("No Credentials found - skipping Append")

    print ("End Operation : {}\n".format(OPERATIONS))
