#!/bin/bash
# Version 1.1

DEBUG=1

# ------ Constants ------
SETTINGS='.mcadmin'
GIT_SETTINGS='.mcadmin.git'
JAR_URL='https://s3.amazonaws.com/MinecraftDownload/launcher/minecraft_server.jar'
SNAPSHOT_URL='https://raw.github.com/chosenken/MCAdmin/master/snapshotURL.sh'
SS_URL_FILE='snapshotURL.sh'
USERNAME=`whoami`
# ------ Variables -----
GIT_INSTALLED=0
GIT_DIR=0
DO_INIT=0
USE_SNAPSHOTS=0
USE_GIT=0
# ------ Default Settings -----
LOGFILE='MCAdmin.log'
GIT_BACKUP_MSG="Game Backup"
SCREEN_NAME='minecraft'
SHUTDOWN_TIMER=10
MC_JAR='minecraft_server.jar'
OPTIONS='nogui'
MAXHEAP=1024
MINHEAP=512
HISTORY=1024
CPU_COUNT=1
INVOCATION="java -Xmx\${MAXHEAP}M -Xms\${MINHEAP}M -XX:+UseConcMarkSweepGC \
-XX:+CMSIncrementalPacing -XX:ParallelGCThreads=\$CPU_COUNT -XX:+AggressiveOpts \
-jar \$MC_JAR \$OPTIONS"
# ------ Functions ------

# Creates the settings file with default settings
makeSettings () {
	echo "# 0/1 - Print DEBUG messages to the log
DEBUG=0
# Log file name
LOGFILE=$LOGFILE
# Commit Message when backing up the game to GIT
GIT_BACKUP_MSG=\"$GIT_BACKUP_MSG\"
# 0/1 - Enables the use of snapshots
USE_SNAPSHOTS=$USE_SNAPSHOTS
# 0/1 - Enables GIT backup support
USE_GIT=$USE_GIT
# Screen name that the server runs under.  Use this to connect to the server outside of this script.
SCREEN_NAME=$SCREEN_NAME
# Amount in time between displaying the shut down message and server shut down
SHUTDOWN_TIMER=$SHUTDOWN_TIMER
# Minecraft Server jar file name
MC_JAR=$MC_JAR
# Additional minecraft server options
OPTIONS=$OPTIONS
# Max Java Heap size in MB
MAXHEAP=$MAXHEAP
# Min Java Heap size in MB
MINHEAP=$MINHEAP
# Max number of lines to keep in history in the screen
HISTORY=$HISTORY
# Number of threads to use running the server
CPU_COUNT=$CPU_COUNT
# Command used to start the server
INVOCATION=\"$INVOCATION\"" > $SETTINGS
}

# Creates the GIT settings file with default settings
makeGitSettings () {
	log "DEBUG" "Making git settings file"
	echo ".mcadmin
.mcadmin.git
.gitignore
*.txt
server.properties
world" > $GIT_SETTINGS
}

# Creates the .gitignore file
makeGitIgnore() {
	log "DEBUG" "Making .gitignore file"
	echo "*.jar
*.sh
*.log*
screenlog*" > .gitignore
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
		log "ERROR" "Incorrect usage of log; $LEVEL $2"
	fi
}

# Checks if curl is installed
checkCurlInstalled() {
	log "DEBUG" "Entered checkCurlInstalled"
	if command -v curl >/dev/null; then
		log "INFO" "Curl is installed"
		CURL_INSTALLED=1
	else
		log "ERROR" "Curl is not installed, checking wget"
		CURL_INSTALLED=0
		checkWgetInstalled
	fi
}

# Checks if wget is installed
checkWgetInstalled() {
	log "DEBUG" "Entered checkWgetInstalled"
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
			makeGitIgnore
			log "INFO" "$GIT_LOG"
		else
			log "WARN" "Tried to initialize a Git repo when one already exists"
		fi
	else
		log "ERROR" "Tried to initialize a Git repo, but Git is NOT installed."
	fi
}

# Downloads the server JAR
downloadJar() {
	log "DEBUG" "Entered downloadJar"
	if [ $USE_SNAPSHOTS -eq 1 ]; then
		downloadSnapshotJar
	else
		downloadMainJar
	fi
}

# Downloads the latest Minecraft Server JAR
downloadMainJar() {
	log "INFO" "Downloading the latest Minecraft Server Jar"
	checkCurlInstalled
	if [ $CURL_INSTALLED -eq 1 ]; then
		curl --silent -O $JAR_URL
	elif [ $WGET_INSTALLED -eq 1 ]; then
		wget -q $JAR_URL
	else
		log "FATAL" "Unable to download the JAR file!  Need either CURL or WGET installed!"
		exit 2
	fi
}

# Downloads the latest Minecraft Server Snapshot JAR.  First downloads the Snapshot
# URL, then using the URL downloads the Snapshot JAR.
downloadSnapshotJar() {
	log "INFO" "Downloading the latest Minecraft Server Snapshot Jar"
	checkCurlInstalled
	# Download using curl
	if [ $CURL_INSTALLED -eq 1 ]; then
		log "INFO" "Downloading the latest Snapshot URL"
		curl --silent -O $SNAPSHOT_URL
		if [ -f $SS_URL_FILE ]; then
			source $SS_URL_FILE
			log "INFO" "Downloading Snapshot Jar"
			curl --silent -O $SS_URL
		else 
			log "ERROR" "Could not download the Snapshot URL.  Aborting Update."
			exit 3
		fi
	# Download using wget
	elif [ $WGET_INSTALLED -eq 1 ]; then
		log "INFO" "Downloading the latest Snapshot URL"
		wget -q $SNAPSHOT_URL
		if [ -f $SS_URL_FILE ]; then
			source $SS_URL_FILE
			log "INFO" "Downloading Snapshot Jar"
			wget -q $SS_URL
		else 
			log "ERROR" "Could not download the Snapshot URL.  Aborting Update."
			exit 3
		fi
	else
		log "FATAL" "Unable to download the JAR file!  Need either CURL or WGET installed!"
		exit 2
	fi
}

startServer() {
	log "DEBUG" "Entered startServer"
	log "DEBUG" "Attempting to start $MC_JAR as $USERNAME"
	if  pgrep -u $USERNAME -f $MC_JAR > /dev/null
	then
		echo "$MC_JAR is already running!"
	else
		log "INFO" "Starting $MC_JAR"
		log "DEBUG" "Invocing: $INVOCATION"
		echo "Starting $MC_JAR"
		screen -h $HISTORY -dmLS $SCREEN_NAME $INVOCATION
		sleep 1
		if  pgrep -u $USERNAME -f $MC_JAR > /dev/null
		then
			echo "$MC_JAR is now running!"
			log "INFO" "$MC_JAR started"
		else
			echo "ERROR!  $MC_JAR failed to start!"
			log "FATAL" "$MC_JAR failed to start"
			exit 2
		fi
	fi
}

stopServer() {
	log "DEBUG" "Entered stopServer"
	if  pgrep -u $USERNAME -f $MC_JAR > /dev/null
	then
		log "INFO" "$MC_JAR coming down"
		screen -p 0 -S $SCREEN_NAME -X eval "stuff 'say SERVER SHUTTING DOWN IN $SHUTDOWN_TIMER SECONDS'\015"
		log "DEBUG" "Shutdown Sleep"
		sleep $SHUTDOWN_TIMER
		screen -p 0 -S $SCREEN_NAME -X eval 'stuff stop\015'
		sleep 10
	else
		echo "Error!  $MC_JAR is not running."
		log "ERROR" "Attempted to stop $MC_JAR when it was not running"
	fi
	if  pgrep -u $USERNAME -f $MC_JAR > /dev/null
	then
		echo "Error!  Could not stop $MC_JAR"
		log "ERROR" "Could not stop $MC_JAR"
	else
		echo "$MC_JAR stopped"
		log "INFO" "$MC_JAR stopped"
	fi
}

saveWorld() {
	log "DEBUG" "Entered saveWorld"
	if pgrep -u $USERNAME -f $MC_JAR > /dev/null
	then
		echo "Saving world..."
		log "INFO" "Saving world"
		screen -p 0 -S $SCREEN_NAME -X eval 'stuff save-all\015'
		sleep 10
	else
		echo "Error!  Cannot save as server is not running."
		log "ERROR" "Server is not running, cannot save."
	fi
}

viewServer() {
	log "DEBUG" "Entered viewServer"
	if pgrep -u $USERNAME -f $MC_JAR > /dev/null
	then
		screen -r $SCREEN_NAME
	else
		echo "Error!  Server is not running."
		log "ERROR" "Cannot view server as it is not running."
	fi
}

gitBackup() {
	log "INFO" "Performing Git Backup"
	if [ $USE_GIT -eq 1 ]; then
		if [ -f $GIT_SETTINGS ]; then
			# Force server to save first if running
			if pgrep -u $USERNAME -f $MC_JAR > /dev/null
			then
				saveWorld
			fi
			while read line; do
				git add $line
			done < $GIT_SETTINGS
			NOW=`date "+%m-%d-%Y %H:%M:%S"`
			git commit -m "$GIT_BACKUP_MSG - $NOW"
		else
			log "ERROR" "Git Settings file is missing."
		fi
	else
		log "ERROR" "Attempted to backup with Git, but Git is not configured!"
	fi
}

setupGit() {
	initGit
}

# Print the usage information
printUsage () {
	echo "Usage:  MCAdmin [option]"
	echo "	help, h 	print this help."
	echo "	start		Starts the Minecraft Server if it is not already running."
	echo "	stop		Stops the Minecraft Server if it is running."
	echo "	save 		Forces the Minecraft Server to Save."
	echo "	view 		Connects to the Screen running the Minecraft Server."
	echo "	git 		Save the game to the Git repository.  Must have configured to use Git."
	echo "	useGit 		Configures MCAdmin to start using Git."
	echo "	init		Initialized MCAdmin.  If a configuration already exists, asks if you"
	echo "			want to overwrite it."
}

# The initalizing function.  Is called when the script is ran from a new directory.
# Initalizes the script and sets up the server.
do_init() {
	clear
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
	read -s USE_GIT
	
	if [ $DEBUG -eq 1 ]; then
		echo "USE_GIT Entered: |$USE_GIT|"
	fi
	if [[ $USE_GIT = '' ]]; then
		USE_GIT=0;
	elif [ $USE_GIT == "y" ] || [ $USE_GIT == "Y" ]; then
		initGit
	else 
		USE_GIT=0
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
	read -s USE_SNAPSHOTS
	
	if [ $DEBUG -eq 1 ]; then
		echo "USE_SNAPSHOTS Entered: |$USE_SNAPSHOTS|"
	fi
	if [[ $USE_SNAPSHOTS = '' ]]; then
		USE_SNAPSHOTS=0
	elif [ $USE_SNAPSHOTS == "y" ] || [ $USE_SNAPSHOTS == "Y" ]; then
		USE_SNAPSHOTS=1
	else 
		USE_SNAPSHOTS=0
	fi

	echo "The script will now download the latest Minecraft Server build."
	echo ""
	downloadJar

	# Update the settings file now that we are down initializing the server
	makeSettings

	if [ $USE_GIT -eq 1 ]; then
		echo "Git has been enabled.  You can set up a cron job to run the git backup"
		echo "at set interavls.  Use the following as an example for running git"
		echo "backup every hour."
		PWD=pwd
		echo "* */1 * * * $pwd/MCadmin.sh git"
	fi

	echo "Setup complete!"

}

reinit() {
	log "INFO" "Entered reinit"
	if [ -f $SETTINGS ]; then
		echo "WARNING!  MCAdmin settings already present!  Are you sure you"
		echo "want to reinitialize the settings?  All your settings will be"
		echo "lost and reset to the default settings."
		echo ""
		echo "This will not affect your current sever configuration or game"
		echo "files."
		echo ""
		echo "If you have git backups enabled, we will peform a back before"
		echo "your settings are reset.  You can always go and revert them"
		echo ""
		echo ""
		echo "Continue with Reinitialization?  [y/N]?"
		read REINIT
		
		if [[ $REINIT = '' ]]; then
			echo "Reinitialization cancled"
			exit 0;
		elif [ $REINIT == 'y' ] || [ $REINIT == 'Y' ]; then
			echo "ARE YOU REALLY SURE YOU WANT TO REINIALIZE? [y/N]"
			read REINIT
			if [[ $REINIT = '' ]]; then
				echo "Reinitialization cancled"
				exit 0;
			elif [ $REINIT == 'y' ] || [ $REINIT == 'Y' ]; then
				echo "Ok, reinitalizing!"
				checkIfGitDir
				if [ $GIT_DIR -eq 1 ]; then
					echo "Performing one last Git Backup"
					gitBackup
					read -p "Backup complete.  Hit [Enter] to begin reinitalization"
				fi
				do_init
			fi
		fi
	else
		do_init
	fi
}
# ------- End Functions ------

case "$1" in
	"help")
		printUsage
		exit 0
	;;
	"h")
		printUsage
		exit 0
	;;
	*)
esac

# Check if we need to set up for the first time
if [ ! -f $SETTINGS ] ; then
	do_init
	exit 0
fi

# Check if the Git settings file exists
if [ ! -f $GIT_SETTINGS ] ; then
    makeGitSettings
fi

source $SETTINGS

# Parse the options now
case "$1" in
	"start")
		startServer
	;;
	"stop")
		stopServer
	;;
	"save")
		saveWorld
	;;
	"view")
		viewServer
	;;
	"git")
		gitBackup
	;;
	"useGit")
		USE_GIT=1
		makeSettings
	;;
	"init")
		reinit
	;;
	*)
		printUsage
		exit 1
	;;
esac