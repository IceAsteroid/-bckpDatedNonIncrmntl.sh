# bckpDatedNonIncrmntl.sh
Back up files with **suffixed with date** especially encrypted containers(such as of LUKS) to mountable storages.

# Note
This is not a script to incrementally back up files, but all the files are suffixed with date, so they reside as several in backup storages. For example:
 ```
 externalStorage $: ls
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
