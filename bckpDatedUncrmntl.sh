#!/bin/bash
# A script to back up files or dirs by suffixing backup files with date to external devices' corresponding directories.
# This means it's to unincrementally back up files or dirs with date as the suffix.
# Oldest backups will automatically be deleted, of course, depending on ${newestNumOfBckpToLeave} of how many to keep.
sh_dir=$(dirname "$0")
source ${sh_dir}/funcLib.sh
DATESuffix=$(date +%y%m%d) #used as suffix to back up files
encrptdCntnrBckpDestDirName="CryptoBlocksUstick" #root dir in backup devices to back up LUKS containers
regularFilesBckpDestDirName="BackupMisc" #root dir in backup devices to back up files
dirsBckpDestDirNameSuffix="_DatedBackup" #suffix added to the name of a dir that stores the backups of the dir to back up
newestNumOfBckpToLeave="4" # leave only the number of backup files/dirs in dest bckp device

printUsage_() { #run as func so shift command won't eliminate parameters
  local count=${#}
  #replace count from 0 to 1 if no para's passed, to make 'for' loop run once.
  for ((i=0; i<${count/0/1}; i++)); do 
    #conditon's passed if no paras are or '-h' is passed
    if [[ "${#}" -eq 0 ]] || [[ "${1}" == -h ]] || \
       #conditon's passed if one of paras is not file or dir
       { { [ ! -d ${1} ] && [ ! -f ${1} ]; } && { echoRed_ "#!Paras Passed Not Files Or Dirs!"; true; } }; then
      cat <<EOF
$(echoGreen_ "## Help Page ##")
$(echoGreen_ "Note:")
# Specify paths of directories or encrypted containers.
# This script will parse them automatically to back up on
#  corresponding directories respectively on backup devices.
# Different types of files or dirs will be backed up in 
#  distinct locations of backup devices' mount point:
#  LUKS encrypted containers in "${encrptdCntnrBckpDestDirName}/";
#  Regular files in "${regularFilesBckpDestDirName}/";
#  Dirs in their own named directories with "${dirsBckpDestDirNameSuffix}" as suffix.
$(echoGreen_ "Usage:")
  $(echo $(basename "$0")) [FILE1 FILE2 ...] 
EOF
      exit
    fi
    shift
  done
}
printUsage_ ${@}

source ${sh_dir}/bckpDvcMng.sh #run backup device management script
#export values from bckpDvcMng.sh
mntedBckpDvcIDsBlksOnBckpDir=($(VMntedBckpDvcIDsBlksOnBckpDir_))
mntedBckpDvcIDsBlksMntPointsOnBckpDir=($(VMntedBckpDvcIDsBlksMntPointsOnBckpDir_))
#mntedBckpDvcIDsBlksMntPointsOnOtherDir=($(VMntedBckpDvcIDsBlksMntPointsOnOtherDir_))

bckpDestDirsToIterate_() { #the top func that contains sub funcs that contains their own sub funcs, and so forth
  declare mntedBckpDvcIDsBlksMntPointOnBckpDir
  declare -a inFuncmntedBckpDvcIDsBlksOnBckpDir inFuncMntedBckpDvcIDsBlksMntPointsOnBckpDir parasOfFilesAndDirsToBckp
  inFuncmntedBckpDvcIDsBlksOnBckpDir=(${mntedBckpDvcIDsBlksOnBckpDir[*]})
  inFuncMntedBckpDvcIDsBlksMntPointsOnBckpDir=(${mntedBckpDvcIDsBlksMntPointsOnBckpDir[@]})
  parasOfFilesAndDirsToBckp=(${@})
  local count=0
  for mntedBckpDvcIDsBlksMntPointOnBckpDir in ${inFuncMntedBckpDvcIDsBlksMntPointsOnBckpDir[@]}; do
    echoGreen_ "## On '${inFuncmntedBckpDvcIDsBlksOnBckpDir[${count}]}'"
    bckpSourItemsToIterate_ ${mntedBckpDvcIDsBlksMntPointOnBckpDir} ${parasOfFilesAndDirsToBckp[@]}
    askToUnmntBckpDvcBlks_ ${mntedBckpDvcIDsBlksMntPointOnBckpDir} ${inFuncmntedBckpDvcIDsBlksOnBckpDir[${count}]}
    ((count+=1))
  done; [[ -z "${mntedBckpDvcIDsBlksMntPointOnBckpDir}" ]] && { echoRed_ "#!Backup Devices Not Mounted! Exit"; exit 2; }
  echo
  echoGreen_ "## Print backup devices' status to check:"
  printMntedBckpDvcIDBlksAndTheirMntPoints_ #print backup devices' state after backup is finished
}

askToUnmntBckpDvcBlks_() { #the func will be run in bckpDestDirsToIterate_
  local mntedBckpDvcIDsBlksMntPointOnBckpDir=${1}
  local inFuncmntedBckpDvcIDsBlksOnBckpDir=${2}
  echoGreen_ "# Asking if to unmount '${inFuncmntedBckpDvcIDsBlksOnBckpDir}' on '${mntedBckpDvcIDsBlksMntPointOnBckpDir}'.."
  while true; do
    read -n1 -p "#(PROMPT)Unmount(y/N)? "; echo
    case $REPLY in
      Y|y) until sudo_ umount ${mntedBckpDvcIDsBlksMntPointOnBckpDir} && { echo "# Unmount Success"; true; } || { echoRed_ "#!Unmount Failed!"; false; }; do
             read -n1 -p "#(PROMPT)Retry(Y/n)? "; echo
             case $REPLY in
               Y|y) sleep 0;;
               *) break 2;;
             esac
           done; break;;
      *) break;;
    esac
  done
}

bckpSourItemsToIterate_() { #the func will be run in bckpDestDirsToIterate_
  declare mntedBckpDvcIDsBlksMntPointOnBckpDir paraOfFileOrDirToBckp
  declare -a parasOfFilesAndDirsToBckp
  mntedBckpDvcIDsBlksMntPointOnBckpDir=${1}
  shift #shift first para out after it's stored, to store the rest of paras that are files or dirs to back up.
  parasOfFilesAndDirsToBckp=(${@})
  #echo mntedBckpDvcIDsBlksMntPointOnBckpDir ${mntedBckpDvcIDsBlksMntPointOnBckpDir[*]}
  #echo parasOfFilesAndDirsToBckp ${parasOfFilesAndDirsToBckp[*]}
  for paraOfFileOrDirToBckp in ${parasOfFilesAndDirsToBckp[@]}; do
    checkOrCreateSourDestDirs_ ${mntedBckpDvcIDsBlksMntPointOnBckpDir} ${paraOfFileOrDirToBckp}
  done
}

checkOrCreateSourDestDirs_() { #the func will be run in bckpSourItemsToIterate_ 
  local destBckpDvcBlksMntPnt=${1}
  local sourFileOrDir=${2}
  declare destBckpDvcBlksMntPntRootDir
  if [[ -f ${sourFileOrDir} ]]; then
    if cryptsetup isLuks ${sourFileOrDir}; then
      destBckpDvcBlksMntPntRootDir="${destBckpDvcBlksMntPnt}/${encrptdCntnrBckpDestDirName}"
    else
      destBckpDvcBlksMntPntRootDir="${destBckpDvcBlksMntPnt}/${regularFilesBckpDestDirName}"
    fi
  elif [[ -d ${sourFileOrDir} ]]; then
    destBckpDvcBlksMntPntRootDir="${destBckpDvcBlksMntPnt}/$(sed 's|/$||'<<<"${sourFileOrDir}" | awk -F/ '{print $NF}')${dirsBckpDestDirNameSuffix}"
  fi
  [[ -d ${destBckpDvcBlksMntPntRootDir} ]] || { echoRed_ "#!Destination Backup Dir Doesn't Exit!"; until sudo_ mkdir --parents ${destBckpDvcBlksMntPntRootDir}; do sleep 1; done; }
  bckpFilesOrDirsOnBckpDvcBlks_ ${destBckpDvcBlksMntPntRootDir} ${sourFileOrDir}; echo
}

bckpFilesOrDirsOnBckpDvcBlks_() { #the func will be run in checkOrCreateSourDestDirs_
  #two lines below ensure the func won't run if things go wrong
  [ -z "${1}" ] && { echoRed_ "#!In ${FUNCNAME[0]}, Argument #1 Isnt Passed!" >&2; exit 2; }
  [ -z "${2}" ] && { echoRed_ "#!In ${FUNCNAME[0]}, Argument #2 Isnt Passed!" >&2; exit 2; }
  local destBckpDvcBlksMntPntRootDir=${1}
  local sourFileOrDir=${2}
  local destBckpFileOrDirName="$(sed 's|/$||'<<<"${sourFileOrDir}" | awk -F/ '{print $NF}')"
  echoGreen_ "# Backing up '${destBckpFileOrDirName}' file/dir.."
  until sudo_ rsync --recursive --links --times --devices --specials ${sourFileOrDir} ${destBckpDvcBlksMntPntRootDir}/${destBckpFileOrDirName}.${DATESuffix} && { echo "# Backup Success"; true; } || { echoRed_ "#!Backup Failed!"; false; }; do
    read -n1 -p "#(PROMPT)Retry(Y/n)? "; echo
    case $REPLY in
      Y|y) sleep 0;;
      *) exit 2;;
    esac
  done
  deleteOlderFilesInBckpDvcBlk_ ${destBckpDvcBlksMntPntRootDir} ${destBckpFileOrDirName}
#  echoGreen_ "# List of destination dir to recheck:"
#  ls ${destBckpDvcBlksMntPntRootDir}
}

deleteOlderFilesInBckpDvcBlk_() { #the func will be run in bckpFilesOrDirsOnBckpDvcBlks_
  #two lines below ensure the func won't delete anything if things go wrong
  [ -z "${1}" ] && { echoRed_ "#!In ${FUNCNAME[0]}, Argument #1 Isnt Passed!" >&2; exit 2; }
  [ -z "${2}" ] && { echoRed_ "#!In ${FUNCNAME[0]}, Argument #2 Isnt Passed!" >&2; exit 2; }
  local destBckpDvcBlksMntPntRootDir=${1}
  local destBckpFileOrDirName=${2}
  declare fileToDelete
  declare -a filesToDelete
  cd ${destBckpDvcBlksMntPntRootDir}
  filesToDelete=($(find . -maxdepth 1 -regex ^\./${destBckpFileOrDirName}\.[0-9]\+\$ | sort --numeric-sort | head --lines=-${newestNumOfBckpToLeave}))
  echoGreen_ "# Leaving '${newestNumOfBckpToLeave}' newest backups.."
  echoRed_ "# Files To Delete: ${filesToDelete[*]:-(null)}"
  for fileToDelete in ${filesToDelete[@]}; do
    until sudo_ rm --recursive --verbose ${fileToDelete} 1>/dev/null || { echoRed_ "#!Deletion Failed!"; false; }; do
      read -n1 -p "#(PROMPT)Retry(Y/n)? "; echo
      case $REPLY in
        Y|y) sleep 0;;
        *) exit 2;;
      esac
    done
  done
  cd - &>/dev/null 
}

notAsRoot_
sync #sync filesystem's cache to physical storages
echoGreen_ "## Backing up files/dirs with date suffix ##"
bckpDestDirsToIterate_ ${@}
















