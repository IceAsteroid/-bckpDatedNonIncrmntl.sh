# bckpDatedNonIncrmntl.sh
Back up files/dirs especially encrypted containers(such as of LUKS) **suffixed with date** to mountable storages.

# Note
This is not a script to incrementally back up files, but all the files are suffixed with date, so they reside as several in backup storages for extra safety instead of only one backup of a file.

However, you can specify how many backups of a file to keep by modifying the integer of the variable for it.

For example:
Encrypted containers will be backed up in a particular directory.
 ```
 externalStorageOne/EncryptedBlockBackupDir $: ls
 luksContainerOne.230110
 luksContainerOne.230210
 luksContainerOne.230310
 
 externalStorageTwo/EncryptedBlockBackupDir $: ls
 luksContainerOne.230110
 luksContainerOne.230210
 luksContainerOne.230310
 ```
 Directories will be backed up to directoires named as their names are suffixed with date.
 ```
 externalStorageOne/DirOne_DatedBackup $: ls
 DirOne.230110
 DirOne.230210
 DirOne.230310
 
 externalStorageTwo/DirOne_DatedBackup $: ls
 DirOne.230110
 DirOne.230210
 DirOne.230310
 ```
 For non-encrypted files.
 ```
 ```

# Features
- Specify blocks(mountable storages) in /dev to be the ones for files to back up to(based on UUIDs of the drives.
- Auto mount all of blocks in conf that are attached to the computer.
- Auto back up given files passed as arguments for the script, to all of mounted storages' specific directories(Can be configured in the script).
Auto mount multiple particular attached drives configured in conf, auto back up specified files to all of configured mounted storages.
- Auto delete oldest backups of a file, if any. Numbers of backups to keep can be modified with a varaible in the script.
- Additional bonus, you can use bckpDvcMng.sh which this script is based on, to mount all the specified blocks at once.

# How to use

# Contribution
If you encounter any problems, just post an issue, and I'll fix them if I can.

# Disclaimer
Despite that this script is programmed in a conservative manner, which means all the important values are stateless & retrieved in real-time when a certain feature is called, and I've used this script to back up mainly for encrypted containers so many years, things would still have a small chance to be broken. So, you should play with it in your own environment a bit before backing up important stuff.

Since, the script relies on blkid command and UUIDs of backup storages to locate specified storages as backup storages in conf. If any of these is broke, things are broken, make sure the UUIDs of blocks including these storages are different.

Use at your own risk:( But I hope you actually end up enjoying it:)
