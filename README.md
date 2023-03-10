# bckpDatedNonIncrmntl.sh
Back up files **suffixed with date** especially encrypted containers(such as of LUKS) to mountable storages.

# Note
This is not a script to incrementally back up files, but all the files are suffixed with date, so they reside as several in backup storages for extra safety instead of only one backup of a file. For example:
 ```
 externalStorageOne $: ls
 luksContainerOne.230110
 luksContainerOne.230210
 luksContainerOne.230310
 
 externalStorageTwo $: ls
 luksContainerOne.230110
 luksContainerOne.230210
 luksContainerOne.230310
 ```
 However, you can specify how many backups of a file to keep by modifying the integer of the variable for it.

# Features
- Specify blocks(mountable storages) in /dev to be the ones for files to back up to(based on UUIDs of the drives.
- Auto mount all of blocks in conf that are attached to the computer.
- Auto back up given files as arguments for the script, to all of mounted storages' specific directories(Can be configured in the script).
Auto mount multiple particular attached drives configured in conf, auto back up specified files to all of configured mounted storages.
- Auto delete oldest backups of a file, if any. Numbers of backups to keep can be modified with a varaible in the script.
- Additional bonus, you can use bckpDvcMng.sh which this script is based on, to mount all the specified blocks at once.

# How to use

# Contribution
If you encounter any problems, just post an issue, and I'll fix them if I can.

# Disclaimer
Despite that this script is programmed in a conservative manner, and I've used this script to back up mainly for encrypted containers so many years, things are still gonna be broke but with small chance. So, you should play with it in your own environment a bit before backing up important stuff.

Use at your own risk:( But I hope you're actually enjoying it.
