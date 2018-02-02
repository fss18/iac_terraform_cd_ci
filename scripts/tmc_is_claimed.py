import requests
import time
import sys

if __name__ == "__main__":
    if(len(sys.argv) != 3):
        print ("Usage: tmc_is_claimed.py IP_ADDRESS TIMEOUT")
        sys.exit()

    _, tmc_ip, timeout = sys.argv
    timeout = int(timeout)
    sleep_time = 30
    while True:
        try:
            TM_ENDPOINT = "http://" + tmc_ip + "/v1/is-claimed/index.php"
            REQUEST = requests.get(TM_ENDPOINT)
            RESPONSE = REQUEST.text
            print ("Claim status for: " + tmc_ip + " is " + RESPONSE)
            if RESPONSE == "true":
                print ("Claim completed - warning: port TCP 7777 may not be ready until a few more mins")
                break
        except:
            print ("TMC status page is not ready yet, IP address = " + tmc_ip)
            time.sleep(sleep_time)

        timeout = timeout - sleep_time
        time.sleep(sleep_time)
        if timeout <= 0:
            print ("Script Timeout")
            sys.exit(1)
