This script is currently a work in progress.

Right, so what does it do?  Well, why not look at the help text?


Usage:  MCAdmin [option]

        help, h         print this help.
        start           Starts the Minecraft Server if it is not already running.
        stop            Stops the Minecraft Server if it is running.
        save            Forces the Minecraft Server to Save.
        view            Connects to the Screen running the Minecraft Server.
        git             Save the game to the Git repository.  Must have configured to use Git.
        useGit          Configures MCAdmin to start using Git.
        init            Initialized MCAdmin.  If a configuration already exists, asks if you
                        want to overwrite it.

It is a simple script for administering a remote Minecraft server, written entirely in BASH.  It manages starting and stopping of the server, forcing the server to save the world, and connecting to the servers screen.  It offers the ability to backup the game world and server files using GIT, allowing you to easily implement versioning.  Someone come a long and grief your brand new house?  Revert!

The script is able to download updated version of the server jar, and can also download snapshots!  Though looking at the code, I don't think I implemented updates just yet o.o

All settings are saved in a .mcadmin file in the same directory.  You can edit the settings as you chose, and they will be reflected the next time you execute the script.

Setting for which files and folders to be included in GIT are stored in .mcadmin.git.  And finally, files that are ignored by git are stored in .gitignore.
