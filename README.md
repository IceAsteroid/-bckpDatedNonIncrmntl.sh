# bckpDatedNonIncrmntl.sh
Back up files especially encrypted containers(such as of LUKS) to mountable storages.

# Features
- Specify blocks(mountable storages) in /dev to be the ones for files to back up to(based on UUIDs of the drives.
- Auto mount all of blocks in conf that are attached to the computer.
- Auto back up given files as arguments for the script, to all of mounted storages' specific directories(Can be configured in the script).
Auto mount multiple particular attached drives configured in conf, auto back up specified files to all of configured mounted storages.
