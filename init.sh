#!/bin/sh
DEMO="Mortgage Demo"
AUTHORS="Red Hat"
PROJECT="git@github.com:jbossdemocentral/rhpam7-mortgage-demo.git"
PRODUCT="Red Hat Process Automation Manager"
TARGET=./target
JBOSS_HOME=$TARGET/jboss-eap-7.1
SERVER_DIR=$JBOSS_HOME/standalone/deployments
SERVER_CONF=$JBOSS_HOME/standalone/configuration/
SERVER_BIN=$JBOSS_HOME/bin
SRC_DIR=./installs
SUPPORT_DIR=./support
PAM_VERSION=7.0.0
PAM_BUSINESS_CENTRAL=rhpam-$PAM_VERSION-business-central-eap7-deployable.zip
PAM_KIE_SERVER=rhpam-$PAM_VERSION-kie-server-ee7.zip
EAP=jboss-eap-7.1.0.zip
#EAP_PATCH=jboss-eap-6.4.7-patch.zip
VERSION=7.0
PROJECT_GIT_REPO=https://github.com/jbossdemocentral/rhpam7-mortgage-demo-repo
PROJECT_GIT_BRANCH=master
PROJECT_GIT_DIR=./support/demo_project_git
PROJECT_GIT_REPO_NAME=examples-rhpam7-mortgage-demo-repo.git
OFFLINE_MODE=false

# wipe screen.
clear

function usage {
      echo "Usage: init.sh [args...]"
      echo "where args include:"
      echo "    -o              run this script in offline mode. The project's Git repo will not be downloaded. Instead a cached version will be used if available."
      echo "    -h              prints this help."
}

#Parse the params
while getopts "oh" opt; do
  case $opt in
    o)
      OFFLINE_MODE=true
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

echo
echo "######################################################################"
echo "##                                                                  ##"
echo "##  Setting up the ${DEMO}                                 ##"
echo "##                                                                  ##"
echo "##                                                                  ##"
echo "##     ####  #   # ####   ###   #   #   #####    #####              ##"
echo "##     #   # #   # #   # #   # # # # #     #     #   #              ##"
echo "##     ####  ##### ####  ##### #  #  #   ###     #   #              ##"
echo "##     # #   #   # #     #   # #     #   #       #   #              ##"
echo "##     #  #  #   # #     #   # #     #  #     #  #####              ##"
echo "##                                                                  ##"
echo "##  brought to you by,                                              ##"
echo "##             ${AUTHORS}                                              ##"
echo "##                                                                  ##"
echo "##                                                                  ##"
echo "##  ${PROJECT}         ##"
echo "##                                                                  ##"
echo "######################################################################"
echo

# make some checks first before proceeding.
if [ -r $SRC_DIR/$EAP ] || [ -L $SRC_DIR/$EAP ]; then
	 echo Product sources are present...
	 echo
else
	echo Need to download $EAP package from http://developers.redhat.com
	echo and place it in the $SRC_DIR directory to proceed...
	echo
	exit
fi

#if [ -r $SRC_DIR/$EAP_PATCH ] || [ -L $SRC_DIR/$EAP_PATCH ]; then
#	echo Product patches are present...
#	echo
#else
#	echo Need to download $EAP_PATCH package from the Customer Portal
#	echo and place it in the $SRC_DIR directory to proceed...
#	echo
#	exit
#fi

if [ -r $SRC_DIR/$PAM_BUSINESS_CENTRAL ] || [ -L $SRC_DIR/$PAM_BUSINESS_CENTRAL ]; then
		echo Product sources are present...
		echo
else
		echo Need to download $PAM_BUSINESS_CENTRAL zip from http://developers.redhat.com
		echo and place it in the $SRC_DIR directory to proceed...
		echo
		exit
fi

#if [ -r $SRC_DIR/$BA_MONITORINGL ] || [ -L $SRC_DIR/$BA_MONITORING ]; then
#		echo Product sources are present...
#		echo
#else
#		echo Need to download $BA_MONITORING zip from http://developers.redhat.com
#		echo and place it in the $SRC_DIR directory to proceed...
#		echo
#		exit
#fi

if [ -r $SRC_DIR/$PAM_KIE_SERVER ] || [ -L $SRC_DIR/$PAM_KIE_SERVER ]; then
		echo Product sources are present...
		echo
else
		echo Need to download $PAM_KIE_SERVER zip from http://developers.redhat.com
		echo and place it in the $SRC_DIR directory to proceed...
		echo
		exit
fi

# Remove the old JBoss instance, if it exists.
if [ -x $JBOSS_HOME ]; then
	echo "  - removing existing JBoss product..."
	echo
	rm -rf $JBOSS_HOME
fi

# Run installers.
echo "Provisioning JBoss EAP now..."
echo
unzip -qo $SRC_DIR/$EAP -d $TARGET

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during JBoss EAP installation!
	exit
fi

#echo
#echo "Applying JBoss EAP 6.4.7 patch now..."
#echo
#$JBOSS_HOME/bin/jboss-cli.sh --command="patch apply $SRC_DIR/$EAP_PATCH"
#
#if [ $? -ne 0 ]; then
#	echo
#	echo Error occurred during JBoss EAP patching!
#	exit
#fi

echo
echo "Deploying Red Hat Business Automation Manager: Business Central now..."
echo
unzip -qo $SRC_DIR/$PAM_BUSINESS_CENTRAL -d $TARGET

if [ $? -ne 0 ]; then
	echo Error occurred during $PRODUCT installation
	exit
fi

echo
echo "Deploying Red Hat Business Automation Manager: Process Server now..."
echo
unzip -qo $SRC_DIR/$PAM_KIE_SERVER -d $SERVER_DIR

if [ $? -ne 0 ]; then
	echo Error occurred during $PRODUCT installation
	exit
fi
touch $SERVER_DIR/kie-server.war.dodeploy

echo
echo "  - enabling demo accounts setup..."
echo
$JBOSS_HOME/bin/add-user.sh -a -r ApplicationRealm -u pamAdmin -p redhatpam1! -ro analyst,admin,manager,user,kie-server,kiemgmt,rest-all --silent
$JBOSS_HOME/bin/add-user.sh -a -r ApplicationRealm -u kieserver -p kieserver1! -ro kie-server --silent

echo "  - setting up demo projects..."
echo
# Copy the default (internal) BPMSuite repo's.
rm -rf $SERVER_BIN/.niogit && mkdir -p $SERVER_BIN/.niogit && cp -r $SUPPORT_DIR/rhpam7-demo-niogit/* $SERVER_BIN/.niogit
# Copy the demo project repo.
if ! $OFFLINE_MODE
then
  # Not in offline mode, so downloading the latest repo. We first download the repo in a temp dir and we only delete the old, cached repo, when the download is succesful.
  echo "  - cloning the project's Git repo from: $PROJECT_GIT_REPO"
  echo
#  rm -rf ./target/temp && git clone --bare $PROJECT_GIT_REPO ./target/temp/bpms-specialtripsagency.git || { echo; echo >&2 "Error cloning the project's Git repo. If there is no Internet connection available, please run this script in 'offline-mode' ('-o') to use a previously downloaded and cached version of the project's Git repo... Aborting"; echo; exit 1; }
  rm -rf ./target/temp && git clone -b $PROJECT_GIT_BRANCH --single-branch $PROJECT_GIT_REPO ./target/temp/$PROJECT_GIT_REPO_NAME || { echo; echo >&2 "Error cloning the project's Git repo. If there is no Internet connection available, please run this script in 'offline-mode' ('-o') to use a previously downloaded and cached version of the project's Git repo... Aborting"; echo; exit 1; }
  pushd ./target/temp/$PROJECT_GIT_REPO_NAME
  # rename the checked-out branch to master.
  echo "Renaming cloned branch '$PROJECT_GIT_BRANCH' to 'master'."
  git branch -m $PROJECT_GIT_BRANCH master
  popd

  echo "  - replacing cached project git repo: $PROJECT_GIT_DIR/$PROJECT_GIT_REPO_NAME"
  echo
#  rm -rf $PROJECT_GIT_DIR/bpms-specialtripsagency.git && mkdir -p $PROJECT_GIT_DIR && cp -R target/temp/bpms-specialtripsagency.git $PROJECT_GIT_DIR/bpms-specialtripsagency.git && rm -rf ./target/temp
  # Make a bare clone of the Git repo.
  rm -rf $PROJECT_GIT_DIR/$PROJECT_GIT_REPO_NAME && mkdir -p $PROJECT_GIT_DIR && git clone --bare target/temp/$PROJECT_GIT_REPO_NAME $PROJECT_GIT_DIR/$PROJECT_GIT_REPO_NAME && rm -rf ./target/temp
else
  echo "  - running in offline-mode, using cached project's Git repo."
  echo
  if [ ! -d "$PROJECT_GIT_DIR" ]
  then
    echo "No project Git repo found. Please run the script without the 'offline' ('-o') option to automatically download the required Git repository!"
    echo
    exit 1
  fi
fi
# Copy the repo to the JBoss BPMSuite installation directory.
rm -rf $SERVER_BIN/.niogit/MySpace/$PROJECT_GIT_REPO_NAME && cp -R $PROJECT_GIT_DIR/$PROJECT_GIT_REPO_NAME $SERVER_BIN/.niogit/MySpace/$PROJECT_GIT_REPO_NAME

echo "  - setting up standalone.xml configuration adjustments..."
echo
cp $SUPPORT_DIR/standalone-full.xml $SERVER_CONF/standalone.xml

echo "  - setup email notification users..."
echo
cp $SUPPORT_DIR/userinfo.properties $SERVER_DIR/business-central.war/WEB-INF/classes/

# Add execute permissions to the standalone.sh script.
echo "  - making sure standalone.sh for server is executable..."
echo
chmod u+x $JBOSS_HOME/bin/standalone.sh

echo "You can now start the $PRODUCT with $SERVER_BIN/standalone.sh"
echo
echo "Login to http://localhost:8080/business-central   (u:pamAdmin / p:redhatpam1!)"
echo

echo "$PRODUCT $VERSION $DEMO Setup Complete."
echo
