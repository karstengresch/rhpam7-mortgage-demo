#!/bin/sh

#BUSINESS_CENTRAL_REST_URL="http://rhpam7-mortgage-rhpamcentr-rhpam7-mortgage-developer.192.168.64.10.nip.io/rest"
BUSINESS_CENTRAL_REST_URL="http://rhpam7-mortgage-rhpamcentr:8080/rest"
SPACE="MySpace"
DEFAULT_GROUPID="com.myspace"
PROJECT_GIT="https://github.com/jbossdemocentral/rhpam7-mortgage-demo-repo.git"
PROJECT_ID="rhpam7-mortgage-demo-repo"
PROJECT_NAME="Mortgage_Demo"
STARTUP_WAIT=60

#First check if the PAM 7 Business Central REST API is available. We'll wait for 60 seconds
echo "Locating Business Central REST API."
count=0
launched=false
until [ $count -gt $STARTUP_WAIT ]
do
  curl -u pamAdmin:redhatpam1! --output /dev/null --silent --head --fail "$BUSINESS_CENTRAL_REST_URL/spaces"
  if [ $? -eq 0 ] ; then
    echo "PAM 7 Business Central REST API started."
    launched=true
    break
  fi
  printf '.'
  sleep 5
  let count=$count+5;
done

#Check that the platform has started, otherwise exit.
if [ $launched = "false" ]
then
  echo "PAM 7 Business Central did not start correctly. Exiting."
  exit 1
else
  echo "PAM 7 Business Central started."
fi

CREATE_SPACE_JSON="{ \"name\":\"$SPACE\", \"description\":null, \"projects\":[], \"owner\":\"pamAdmin\", \"defaultGroupId\":\"$DEFAULT_GROUPID\"}"
#Create a space
STATUSCODE=$(curl -H "Accept: application/json" -H "Content-Type: application/json" -f -X POST  -d "$CREATE_SPACE_JSON" -u "pamAdmin:redhatpam1!" --silent --output /dev/null --write-out "%{http_code}" "$BUSINESS_CENTRAL_REST_URL/spaces")

if [ $STATUSCODE -ne 202 ] ; then
    echo "Error creating new Space. Exiting"
    exit 1
else
    echo "Creating new Space."
fi

# Wait for the space to be created
echo "Waiting for space to be created."
count=0
created=false
until [ $count -gt $STARTUP_WAIT ]
do
  curl -u pamAdmin:redhatpam1! --output /dev/null --silent --head --fail "$BUSINESS_CENTRAL_REST_URL/spaces/$SPACE"
  if [ $? -eq 0 ] ; then
    echo "\nSpace created."
    created=true
    break
  fi
  printf '.'
  sleep 5
  let count=$count+5;
done

# Give the platform a bit of time before we request the project to be cloned. Not pretty, but don't see another way atm ...
sleep 3

# Check if the project is already present. If it is, we simply skip cloning
#Create a space
curl -u pamAdmin:redhatpam1! --output /dev/null --silent --fail "$BUSINESS_CENTRAL_REST_URL/spaces/$SPACE/projects/$PROJECT_NAME"
if [ $? -ne 0 ] ; then
   echo "Cloning project.."
   # And clone the project into that space
   CLONE_GIT_JSON="{\"name\":\"$PROJECT_ID\", \"gitURL\":\"$PROJECT_GIT\"}"
   STATUSCODE=$(curl -H "Accept: application/json" -H "Content-Type: application/json" -f -X POST  -d "$CLONE_GIT_JSON" -u "pamAdmin:redhatpam1!" --silent --output /dev/null --write-out "%{http_code}" "$BUSINESS_CENTRAL_REST_URL/spaces/$SPACE/git/clone")
   if [ $STATUSCODE -ne 202 ] ; then
      echo "Error cloning Demo Git repository. Exiting"
      exit 1
   else
      echo "Demo project cloned."
   fi
else
   echo "Project already exists. Not cloning again."
fi
