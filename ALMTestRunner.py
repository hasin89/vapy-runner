'''
Created on 18 sty 2018

@author: Tomasz Hasinski
'''

import socket, requests, sys
from requests.auth import HTTPBasicAuth
import json
from debugMessage import debugMessage, errorMessage

def jsonGetRequest(path):
    url = KYLOS_URL + path
    response = requests.get(url, auth=auth)
    
    debugMessage("Fetching Test Data: " + response.request.url)
    
    responseText = response.text
    if not responseText.startswith('{'):
        raise Exception('No JSON returned.\n' + 'Request: ' + str(url) + '\nResponse Contents: ' + str(responseText) )
    
    testEnv = json.loads(responseText)
    return testEnv
    
def jsonPostRequest(path, requestBody = {}):
    url = KYLOS_URL + path
    headers = {'content-type': 'application/x-www-form-urlencoded'}
    requestBody.update({'api':""})
            
    response = requests.post(url, auth=auth, headers=headers, data=requestBody)
    
    print response.request.url
    if requestBody:
        print 'Request body:'
        prettyPrintJson(requestBody)
    
    responseText = response.text
    if not responseText.startswith('{'):
        raise Exception('No JSON returned.\n' + 'Request: ' + str(url) + '\nResponse Contents: ' + str(responseText) )
    
    testEnv = json.loads(responseText)
    return testEnv

def prettyPrintJson(responseJson):
    if responseJson:
        print json.dumps(responseJson, sort_keys = True, indent = 4)
        
if __name__ == '__main__':
    
    KYLOS_URL = 'https://digitalstrom.kylos.pl'
    auth = HTTPBasicAuth('aizo', 'A1z0d$S')
    myHostname = socket.gethostname()
    path = '/ac2/webservice.php?whoami=' + str(myHostname)

    
    if len(sys.argv) > 1:
        try:
            debugMessage('Using the command line arguments')
            parameters = str(sys.argv[1]).split(";")
            
            devices = str(parameters[0])
            testPath = str(parameters[1])
            testName = str(parameters[2])
            testArgs = '|'.join(parameters[3:])
            
        except Exception as e:
            debugMessage(e)
            sys.exit()    
    else:
    #default parameters
        debugMessage('Using the defalut arguments')
        devices = "False"
        testPath = ""
        testName = "samplePythonTest.py"
        testArgs = "1|2|3"
    
    if devices == "True":
        path+= '&devices=true'
    testEnv = jsonGetRequest(path)
    testEnvResponse = testEnv
        
    envName = testEnv['name']
    dssUrl = testEnv['dssUrl']
    dssUrlLocal = testEnv['dssUrlLocal']
    dssUrlRemote = testEnv['dssUrlRemote']
    dssDsid = testEnv['dssDsid']
    dssMac = testEnv['dssMac']
    dssUsername = testEnv['dssUsername']
    dssPassword = testEnv['dssPassword']
    emailUsername = testEnv['email_name']
    emailPassword = testEnv['email_password']
    cloudUsername = testEnv['cloud_email']
    cloudPassword = testEnv['cloud_password']
    cloudName = testEnv['cloud_name']
    cloudApartmentId = testEnv['cloud_apartment_id']
    twitterUsername = testEnv['twitter_user']
    twitterPassword = testEnv['twitter_password']
    testServerUrl = testEnv['webpy_link']
    testServerPort = testEnv['webpy_port']    
    feedName = testEnv['feed']
    
    if devices == "True":
        devices = testEnv['devices']
    #http://192.168.0.104:8080/executeTest?testName=samplePythonTest.py&testArgs=1|2|3
    webpyURL = testServerUrl + ":" + testServerPort + "/executeTest?testPath=" + testPath + "&testName=" + testName + "&testArgs=" + testArgs
    debugMessage("Triggering the test: " + webpyURL)
    response = requests.get(webpyURL)
    responseText = response.text
    if not responseText.startswith('{'):
        raise Exception('No JSON returned.\n' + 'Request: ' + str(webpyURL) + '\nResponse Contents: ' + str(responseText) )
    
    testEnv = json.loads(responseText)
    #debugMessage("JSON result: ")
    debugMessage("Success: " + str(testEnv['success']))
    
    #STEPS parsing
    stdout = testEnv['stdout']
    startIdx = stdout.find("STEPS JSON:{")
    if startIdx > -1:
        stepsStr = stdout[startIdx:]
        
        testEnv['stdout'] = testEnv['stdout'].replace(stepsStr, "STEPS PROCESSED")
        
        startIdx = stepsStr.find("{")    
        #debugMessage(testEnv)
        if startIdx > -1:
            stepsStr = stepsStr[startIdx:]
            steps = json.loads(stepsStr)
    else:
        steps = {'length': 0}
    #passing JSON returned by webpy to ALM
    print testEnv
    
    #passing steps to ALM
    
    for x in range(1,steps['length']+1):
        print steps[str(x)]
            
            