
# wipe screen
Clear-Host

$PROJECT_HOME = $PSScriptRoot
$DEMO="Mortgage Demo"
$AUTHORS="Red Hat"
$PROJECT="git@github.com:jbossdemocentral/rhpam7-mortgage-demo.git"
$PRODUCT="Red Hat Procss Automation Manager"
$TARGET="$PROJECT_HOME\target"
$JBOSS_HOME="$TARGET\jboss-eap-7.1"
$SERVER_DIR="$JBOSS_HOME\standalone\deployments\"
$SERVER_CONF="$JBOSS_HOME\standalone\configuration\"
$SERVER_BIN="$JBOSS_HOME\bin"
$SRC_DIR="$PROJECT_HOME\installs"
$SUPPORT_DIR="$PROJECT_HOME\support"
$PRJ_DIR="$PROJECT_HOME\projects"
$PAM_VERSION="7.0.0"
$PAM_BUSINESS_CENTRAL="rhpam-$PAM_VERSION-business-central-eap7-deployable.zip"
$PAM_KIE_SERVER="rhpam-$PAM_VERSION-kie-server-ee7.zip"
$EAP="jboss-eap-7.1.0.zip"
#$EAP_PATCH="jboss-eap-6.4.7-patch.zip"
$VERSION="7.0"
$PROJECT_GIT_REPO="https://github.com/jbossdemocentral/rhpam7-mortgage-demo-repo"
$PROJECT_GIT_BRANCH="master"
$PROJECT_GIT_DIR="$PROJECT_HOME\support\demo_project_git"
$PROJECT_GIT_REPO_NAME="examples-rhpam7-mortgage-demo-repo.git"
$OFFLINE_MODE="false"

If ($h) {
	Write-Host "Usage: init.ps1 [args...]"
    Write-Host "where args include:"
    Write-Host "    -o              run this script in offline mode. The project's Git repo will not be downloaded. Instead a cached version will be used if available."
    Write-Host "    -h              prints this help."
	exit
}

Write-Host "######################################################################"
Write-Host "##                                                                  ##"
Write-Host "##  Setting up the ${DEMO}            ##"
Write-Host "##                                                                  ##"
Write-Host "##                                                                  ##"
Write-Host "##     ####  #   # ####   ###   #   #   #####    #####              ##"
Write-Host "##     #   # #   # #   # #   # # # # #     #     #   #              ##"
Write-Host "##     ####  ##### ####  ##### #  #  #   ###     #   #              ##"
Write-Host "##     # #   #   # #     #   # #     #   #       #   #              ##"
Write-Host "##     #  #  #   # #     #   # #     #  #     #  #####              ##"
Write-Host "##                                                                  ##"
Write-Host "##  brought to you by,                                              ##"
Write-Host "##             $AUTHORS                                             ##"
Write-Host "##                                                                  ##"
Write-Host "##                                                                  ##"
Write-Host "##  $PROJECT           ##"
Write-Host "##                                                                  ##"
Write-Host "######################################################################`n"


If (Test-Path "$SRC_DIR\$EAP") {
	Write-Host "Product sources are present...`n"
} Else {
	Write-Host "Need to download $EAP package from the Customer Support Portal"
	Write-Host "and place it in the $SRC_DIR directory to proceed...`n"
	exit
}

#If (Test-Path "$SRC_DIR\$EAP_PATCH") {
#	Write-Host "Product patches are present...`n"
#} Else {
#	Write-Host "Need to download $EAP_PATCH package from the Customer Support Portal"
#	Write-Host "and place it in the $SRC_DIR directory to proceed...`n"
#	exit
#}

If (Test-Path "$SRC_DIR\$PAM_BUSINESS_CENTRAL") {
	Write-Host "Product sources are present...`n"
} Else {
	Write-Host "Need to download $PAM_BUSINESS_CENTRAL package from the Customer Support Portal"
	Write-Host "and place it in the $SRC_DIR directory to proceed...`n"
	exit
}

If (Test-Path "$SRC_DIR\$PAM_KIE_SERVER") {
	Write-Host "Product sources are present...`n"
} Else {
	Write-Host "Need to download $PAM_KIE_SERVER package from the Customer Support Portal"
	Write-Host "and place it in the $SRC_DIR directory to proceed...`n"
	exit
}

#Test whether Java is available.
#if ((Get-Command "java.exe" -ErrorAction SilentlyContinue) -eq $null)
#{
#   Write-Host "The 'java' command is required but not available. Please install Java and add it to your PATH.`n"
#   exit
#}

#if ((Get-Command "javac.exe" -ErrorAction SilentlyContinue) -eq $null)
#{
#   Write-Host "The 'javac' command is required but not available. Please install Java and add it to your PATH.`n"
#   exit
#}

# Test whether 7Zip is available.
# We use 7Zip because it seems to be one of the few ways to extract the BRMS zip file without hitting the 260 character limit problem of the Windows API.
# This is definitely not ideal, but I can't unzip without problems when using the default Powershell unzip utilities.
# 7-Zip can be downloaded here: http://www.7-zip.org/download.html
if ((Get-Command "7z.exe" -ErrorAction SilentlyContinue) -eq $null)
{
   Write-Host "The '7z.exe' command is required but not available. Please install 7-Zip.`n"
	 Write-Host "7-Zip is used to overcome the Windows 260 character limit on paths while extracting the Red Hat Process Automation Manager ZIP file.`n"
	 Write-Host "7-Zip can be donwloaded here: http://www.7-zip.org/download.html`n"
	 Write-Host "Please make sure to add '7z.exe' to your 'PATH' after installation.`n"
   exit
}

# Remove the old installation if it exists
If (Test-Path "$JBOSS_HOME") {
	Write-Host "Removing existing installation.`n"
	# The "\\?\" prefix is a trick to get around the 256 path-length limit in Windows.
	# If we don't do this, the Remove-Item command fails when it tries to delete files with a name longer than 256 characters.
	Remove-Item "\\?\$JBOSS_HOME" -Force -Recurse
}

#Run installers.
Write-Host "Deploying JBoss EAP now..."
# Using 7-Zip. This currently seems to be the only way to overcome the Windows 260 character path limit.
$argList = "x -o$TARGET -y $SRC_DIR\$EAP"
$unzipProcess = (Start-Process -FilePath 7z.exe -ArgumentList $argList -Wait -PassThru -NoNewWindow)

If ($unzipProcess.ExitCode -ne 0) {
	Write-Error "Error occurred during JBoss EAP installation."
	exit
}


<#
Write-Host "Applying JBoss EAP patch now...`n"
Write-Host "The patch process will run in a separate window. Please wait for the 'Press any key to continue ...' message...`n"
$argList = '--command="patch apply ' + "$SRC_DIR\$EAP_PATCH" + ' --override-all"'
$patchProcess = (Start-Process -FilePath "$JBOSS_HOME\bin\jboss-cli.bat" -ArgumentList $argList -Wait -PassThru)
Write-Host "Process finished with return code: " $patchProcess.ExitCode
Write-Host ""

If ($patchProcess.ExitCode -ne 0) {
	Write-Error "Error occurred during JBoss EAP patch installation."
	exit
}

Write-Host "JBoss EAP patch applied succesfully!`n"
#>

Write-Host "Deploying Process Automation Manager Business Central now..."
# Using 7-Zip. This currently seems to be the only way to overcome the Windows 260 character path limit.
$argList = "x -o$TARGET -y $SRC_DIR\$PAM_BUSINESS_CENTRAL"
$unzipProcess = (Start-Process -FilePath 7z.exe -ArgumentList $argList -Wait -PassThru -NoNewWindow)

If ($unzipProcess.ExitCode -ne 0) {
	Write-Error "Error occurred during Process Automation Manager Business Central installation."
	exit
}

Write-Host "Deploying Process Automation Manager Process Server now..."
# Using 7-Zip. This currently seems to be the only way to overcome the Windows 260 character path limit.
$argList = "x -o$JBOSS_HOME\standalone\deployments -y $SRC_DIR\$PAM_KIE_SERVER"
$unzipProcess = (Start-Process -FilePath 7z.exe -ArgumentList $argList -Wait -PassThru -NoNewWindow)

If ($unzipProcess.ExitCode -ne 0) {
	Write-Error "Error occurred during Process Automation Manager Process Server installation."
	exit
}
New-Item -ItemType file $JBOSS_HOME\standalone\deployments\kie-server.war.dodeploy
Write-Host ""

Write-Host "- enabling demo accounts setup ...`n"
$argList1 = "-a -r ApplicationRealm -u pamAdmin -p 'redhatpam1!' -ro 'analyst,admin,manager,user,kie-server,kiemgmt,rest-all' --silent"
$argList2 = "-a -r ApplicationRealm -u kieserver -p 'kieserver1!' -ro 'kie-server' --silent"
try {
	Invoke-Expression "$JBOSS_HOME\bin\add-user.ps1 $argList1"
  Invoke-Expression "$JBOSS_HOME\bin\add-user.ps1 $argList2"
} catch {
	Write-Error "Error occurred during user account setup."
	exit
}

################################# Begin setup demo projects ##########################################

Write-Host "- Setting up demo projects...`n"

If (Test-Path "$SERVER_BIN\.niogit\") {
Remove-Item "$SERVER_BIN\.niogit\" -Force -Recurse
}
New-Item -ItemType directory -Path "$SERVER_BIN\.niogit\" | Out-Null
Copy-Item "$SUPPORT_DIR\rhpam7-demo-niogit\*" "$SERVER_BIN\.niogit\" -force -recurse
If (! $o) {
  # Not in offline mode, so downloading the latest repo. We first download the repo in a temp dir and we only delete the old, cached repo, when the download is succesful.
  Write-Host "  - cloning the project's Git repo from: $PROJECT_GIT_REPO`n"
  If (Test-Path "$PROJECT_HOME\target\temp") {
	Remove-Item "$PROJECT_HOME\target\temp" -Force -Recurse
  }
  $argList = "clone --bare $PROJECT_GIT_REPO $PROJECT_HOME\target\temp\$PROJECT_GIT_REPO_NAME"
  $gitProcess = (Start-Process -FilePath "git" -ArgumentList $argList -Wait -PassThru -NoNewWindow)
  If ($gitProcess.ExitCode -ne 0) {
		Write-Host "Error cloning the project's Git repo. If there is no Internet connection available, please run this script in 'offline-mode' ('-o') to use a previously downloaded and cached version of the project's Git repo... Aborting"
		exit 1
  }
  Write-Host ""
  Write-Host "  - replacing cached project git repo: $PROJECT_GIT_DIR/$PROJECT_GIT_REPO_NAME`n"
  If (Test-Path "$PROJECT_GIT_DIR") {
	Remove-Item "$PROJECT_GIT_DIR" -Force -Recurse
  }
  New-Item -ItemType directory -Path "$PROJECT_GIT_DIR"
  Copy-Item "$PROJECT_HOME\target\temp\$PROJECT_GIT_REPO_NAME" "$PROJECT_GIT_DIR\$PROJECT_GIT_REPO_NAME" -Force -Recurse
  Remove-Item "$PROJECT_HOME\target\temp" -Force -Recurse
} else {
  Write-Host "  - running in offline-mode, using cached project's Git repo.`n"

  If (-Not (Test-Path "$PROJECT_GIT_DIR\$PROJECT_GIT_REPO_NAME")) {
    Write-Host "No project Git repo found. Please run the script without the 'offline' ('-o') option to automatically download the required Git repository!`n"
    exit 1
  }
}
# Copy the repo to the JBoss BPMSuite installation directory.
Remove-Item "$SERVER_BIN\.niogit\MySpace\$PROJECT_GIT_REPO_NAME" -Force -Recurse
Copy-Item "$PROJECT_GIT_DIR\$PROJECT_GIT_REPO_NAME" "$SERVER_BIN\.niogit\MySpace\$PROJECT_GIT_REPO_NAME" -force -recurse

################################# End setup demo projects ##########################################

Write-Host "- setting up standalone.xml configuration adjustments...`n"
Copy-Item "$SUPPORT_DIR\standalone-full.xml" "$SERVER_CONF\standalone.xml" -force

Write-Host "- setup email task notification user...`n"
Copy-Item "$SUPPORT_DIR\userinfo.properties" "$SERVER_DIR\business-central.war\WEB-INF\classes\" -force

Write-Host "============================================================================"
Write-Host "=                                                                          ="
Write-Host "=  You can now start the $PRODUCT with:                             ="
Write-Host "=                                                                          ="
Write-Host "=   $SERVER_BIN\standalone.ps1                          ="
Write-Host "=       or                                                                   ="
Write-Host "=   $SERVER_BIN\standalone.bat                          ="
Write-Host "=                                                                          ="
Write-Host "=  Login into business central at:                                         ="
Write-Host "=                                                                          ="
Write-Host "=    http://localhost:8080/business-central  (u:pamAdmin / p:redhatpam1!)    ="
Write-Host "=                                                                          ="
Write-Host "=  See README.md for general details to run the various demo cases.        ="
Write-Host "=                                                                          ="
Write-Host "=  $PRODUCT $VERSION $DEMO Setup Complete.                  ="
Write-Host "=                                                                          ="
Write-Host "============================================================================"
