#!/bin/bash
# Version 1

DEBUG=1

# ------ Constants ------
SETTINGS='.mcadmin'
GIT_SETTINGS='.mcadmin.git'
MC_JAR='minecraft_server.jar'
JAR_URL='https://s3.amazonaws.com/MinecraftDownload/launcher/minecraft_server.jar'
# ------ Variables -----
GIT_INSTALLED=0
GIT_DIR=0
DO_INIT=0
USE_SNAPSHOTS=0
USE_GIT=0
# ------ Functions ------

# Creates the settings file with default settings
makeSettings () {
	echo 'DEBUG=0
LOGFILE="MCAdmin.log"
USE_SNAPSHOTS=0
USE_GIT=0' > $SETTINGS
}

# Update the settings file
updateSettings() {
	echo 'DEBUG=0
LOGFILE="MCAdmin.log"
USE_SNAPSHOTS=$USE_SNAPSHOTS
USE_GIT=$USE_GIT' > $SETTINGS
}

# Creates the GIT settings file with default settings
makeGitSettings () {
	log 'DEBUG' "Making git settings file"
	echo '*.txt
server.properties
world' > $GIT_SETTINGS
}

# Creates the .gitignore file
makeGitIgnore() {
	log 'DEBUG' "Making .gitignore file"
	echo '*.jar
*.sh' > .gitignore
}

# Log function, logs passed message to the log file.  Log file
# defined in settings file.
log () {
	LEVEL=$1
	if [ ${#LEVEL} -lt 5 ]; then
		LEVEL=$LEVEL" "
	fi
	if [ "$LEVEL" != "" -a "$2" != "" ]; then
		NOW=`date "+%m-%d-%Y %H:%M:%S"`
		echo $NOW "$LEVEL - $2" >> $LOGFILE
	else
		log 'ERROR' 'Incorrect usage of log; "$LEVEL" "$2"'
	fi
}

checkCurlInstalled() {
	if command -v curl >/dev/null; then
		log "INFO" "Curl is installed"
		CURL_INSTALLED=1
	else
		log "ERROR" "Curl is not installed, checking wget"
		CURL_INSTALLED=0
		checkWgetInstalled
	fi
}

checkWgetInstalled() {
	if command -v wget >/dev/null; then
		log "INFO" "wget is installed"
		WGET_INSTALLED=1
	else
		log "ERROR" "wget is not installed"
		WGET_INSTALLED=0
	fi
}

# Checks if Git is installed
checkGitInstalled() {
	log "DEBUG" "Entered checkGitInstalled"
	if command -v git >/dev/null; then
		GIT_INSTALLED=1;
		log "INFO" "Git is installed."
		USE_GIT=1
	else
		log "INFO" "Git is not installed."
		echo "Git not installed, unable to use Git."
		USE_GIT=0
	fi
}

# Checks if there is already a Git repository present
checkIfGitDir() {
	log "DEBUG" "Entered checkIfGitDir"
	if [ -d .git ]; then
		GIT_DIR=1
	else
		GIT_DIR=0
	fi
}

# Initializes a Git repository
initGit() {
	log "DEBUG" "Entered initGit"
	checkGitInstalled
	checkIfGitDir
	if [ $GIT_INSTALLED -eq 1 ]; then
		USE_GIT=1
		if [ $GIT_DIR -eq 0 ]; then
			GIT_LOG=`git init`
			log "INFO" "$GIT_LOG"
		else
			log "WARN" "Tried to initialize a Git repo when one already exists"
		fi
	else
		log "ERROR" "Tried to initialize a Git repo, but Git is NOT installed."
	fi
}

# Downloads the latest Minecraft Server JAR
downloadJar() {
	log "INFO" "Downloading the latest Minecraft Server Jar"
	checkCurlInstalled
	if [ $CURL_INSTALLED -eq 1 ]; then
		CURL_LOG='curl -O $JAR_URL'
		log "INFO" "&CURL_LOG"
	else if [ $WGET_INSTALLED -eq 1 ]; then
		WGET_LOG='wget $JAR_URL'
		log "INFO" "$WGET_LOG"
	else
		log "FATAL" "Unable to download the JAR file!  Need either CURL or WGET installed!"
		exit 2
	fi
}


# The initalizing function.  Is called when the script is ran from a new directory.
# Initalizes the script and sets up the server.
do_init() {
	echo "Welcome to MCAdmin, the (somewhat) simple Minecraft Command Line Admin tool!"
	echo "We just need to go through a quick setup here with some questions."
	echo ""
	echo ""
	echo "GIT:  Git is a Source Control Management software commenly used for managing"
	echo "source code.  It can also be used as a easy back up tool, creating snapshots"
	echo "of a directory, allowing you to revert to them at any time.  This is greate"
	echo "for backups with Minecraft.  If you happen to get a greifer, you can always"
	echo "revert to an earlier save and undo all the grief....a long with any other"
	echo "changes..."
	echo ""
	echo "Would you like to use Git to backup your Minecraft Saves? [y/N] "
	read USE_GIT

	if [ $USE_GIT == "y" ] || [ $USE_GIT == "Y" ]; then
		initGit
	fi

	echo ""
	echo "Snapshots:  Snapshots are the 'beta' builds of Minecraft, and are generally"
	echo "released weekly.  They contain new and imporved game play, but may be"
	echo "unstable.  Also, you can not really downgrade a world save from a snapshot"
	echo "build to a release build, IE you are using MC 1.7.4, then use snapshot"
	echo "13w01b, you shouldn't revert to MC 1.7.4 as your world save may have new"
	echo "blocks in it that are not in the old version."
	echo ""
	echo "USE WITH CAUTION!!!!  MAKE SURE YOU FULLY UNDERSTAND WHAT YOU ARE DOING"
	echo "IF YOU CHOSE TO USE SNAPSHOTS!"
	echo ""
	echo "Would you like to use Snapshots? [y/N] "
	read USE_SNAPSHOTS

	if [ $USE_SNAPSHOTS == "y" ] || [ $USE_SNAPSHOTS == "Y" ]; then
		USE_SNAPSHOTS=1
	fi

	echo "The script will now download the latest Minecraft Server build."
	downloadJar

	# Update the settings file now that we are down initializing the server
	updateSettings

}
# ------- End Functions ------

#  Check if the settings file exists
if [ ! -f $SETTINGS ] ; then
	makeSettings
	DO_INIT=1
fi
source $SETTINGS
# Check if the Git settings file exists
if [ ! -f $GIT_SETTINGS ] ; then
    makeGitSettings
fi

# Check if we need to set up for the first time
if [ $DO_INIT -eq 1 ]; then
	do_init
fi