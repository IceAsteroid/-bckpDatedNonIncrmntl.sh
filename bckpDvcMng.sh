#!/bin/bash
# A function library/script used to add & remove & show devices to, from backup conf, and mount them for backup
# Run the script alone to have a menu printed to get the taste of it.
sh_dir=$(dirname "$0")
source ${sh_dir}/funcLib.sh

bckpDvcConfDir="${HOME}/.config/bckp_sh"
bckpDvcConf="${bckpDvcConfDir}/bckp_dvc_id.txt"
bckpMountDir="/mnt/BckpMountDir"
bckpMntSubDirPrfx="bckpDvc_"

[ -d "${bckpDvcConfDir}" ] || mkdir ${bckpDvcConfDir}
[ -f "${bckpDvcConf}" ] || touch ${bckpDvcConf}
[ -d "${bckpMountDir}" ] || sudo_ mkdir ${bckpMountDir}

VBckpDvcConfIDs_() {
  declare -a bckpDvcIDs
  mapfile -t bckpDvcIDs < ${bckpDvcConf}
  echo ${bckpDvcIDs[@]}
}

VAttchdBckpDvcIDs_() {
  declare -a attchdBckpDvcIDs
  declare bckpDvcID 
  for bckpDvcID in $(VBckpDvcConfIDs_); do
    if blkid -U ${bckpDvcID} -o device &>/dev/null; then
      attchdBckpDvcIDs+=(${bckpDvcID})
    fi
  done
  echo ${attchdBckpDvcIDs[@]}
}

VAttchdBckpDvcIDsBlks_() { #values' order based on VAttchdBckpDvcIDs_
  declare attchdBckpDvcID
  declare -a attchdBckpDvcIDsBlks
  for attchdBckpDvcID in $(VAttchdBckpDvcIDs_); do
    attchdBckpDvcIDsBlks+=($(blkid -U ${attchdBckpDvcID} -o device))
  done
  echo ${attchdBckpDvcIDsBlks[@]}
}

VMntedBckpDvcIDs_() {
  declare attchdBckpDvcID
  declare -a mntedBckpDvcIDs
  for attchdBckpDvcID in $(VAttchdBckpDvcIDs_); do
    if grep --quiet --no-messages "$(blkid -U ${attchdBckpDvcID} -o device)" /proc/mounts; then
      mntedBckpDvcIDs+=(${attchdBckpDvcID})
    fi
  done
  echo ${mntedBckpDvcIDs[@]}
}

VMntedBckpDvcIDsBlks_() { #values' order based on VMntedBckpDvcIDs_
  declare mntedBckpDvcID
  declare -a mntedBckpDvcIDsBlks
  for mntedBckpDvcID in $(VMntedBckpDvcIDs_); do
    mntedBckpDvcIDsBlks+=($(blkid -U ${mntedBckpDvcID} -o device))
  done
  echo ${mntedBckpDvcIDsBlks[@]}
}

VMntedBckpDvcIDsBlksMntPoints_() { #values' order based on VMntedBckpDvcIDsBlks_
  declare mntedBckpDvcIDsBlk
  declare -a mntedBckpDvcIDsBlksMntPoints
  for mntedBckpDvcIDsBlk in $(VMntedBckpDvcIDsBlks_); do
    mntedBckpDvcIDsBlksMntPoints+=($(grep ${mntedBckpDvcIDsBlk} /proc/mounts | awk '{print $2}'))
  done
  echo ${mntedBckpDvcIDsBlksMntPoints[@]}
}

VMntedBckpDvcIDsBlksOnBckpDir_() { #values' order based on VMntedBckpDvcIDsBlksMntPoints_, on VMntedBckpDvcIDsBlks_
  declare MntedBckpDvcIDsBlksMntPoint
  declare -a MntedBckpDvcIDsBlks MntedBckpDvcIDsBlksOnBckpDir
  MntedBckpDvcIDsBlks=($(VMntedBckpDvcIDsBlks_))
  local count=0
  for MntedBckpDvcIDsBlksMntPoint in $(VMntedBckpDvcIDsBlksMntPoints_); do
    if grep --quiet --no-messages "${bckpMountDir}" <<<"${MntedBckpDvcIDsBlksMntPoint}"; then
      MntedBckpDvcIDsBlksOnBckpDir+=(${MntedBckpDvcIDsBlks[$count]})
    fi
  ((count+=1))
  done
  echo ${MntedBckpDvcIDsBlksOnBckpDir[@]}
}

VMntedBckpDvcIDsBlksOnOtherDir_() { #values' order based on VMntedBckpDvcIDsBlksMntPoints_, on VMntedBckpDvcIDsBlks_
  declare -a MntedBckpDvcIDsBlks MntedBckpDvcIDsBlksOnOtherDir
  MntedBckpDvcIDsBlks=($(VMntedBckpDvcIDsBlks_))
  local count=0
  for MntedBckpDvcIDsBlksMntPoint in $(VMntedBckpDvcIDsBlksMntPoints_); do
    if ! grep --quiet --no-messages "${bckpMountDir}" <<<"${MntedBckpDvcIDsBlksMntPoint}"; then
      MntedBckpDvcIDsBlksOnOtherDir+=(${MntedBckpDvcIDsBlks[$count]})
    fi
  ((count+=1))
  done
  echo ${MntedBckpDvcIDsBlksOnOtherDir[@]}
}

VAttchdButNotMntedBckpDvcIDsBlks_() {
  declare attchdBckpDvcIDsBlk mntedBckpDvcIDsBlk
  declare -a attchdButNotMntedBckpDvcIDsBlks
  attchdButNotMntedBckpDvcIDsBlks=($(VAttchdBckpDvcIDsBlks_))
  local count=0
  for attchdBckpDvcIDsBlk in $(VAttchdBckpDvcIDsBlks_); do
    for mntedBckpDvcIDsBlk in $(VMntedBckpDvcIDsBlks_); do
      [[ "${attchdBckpDvcIDsBlk}" =~ ${mntedBckpDvcIDsBlk} ]] && unset attchdButNotMntedBckpDvcIDsBlks[${count}]
    done
    ((count+=1))
  done
  echo ${attchdButNotMntedBckpDvcIDsBlks[@]}
}

VMntedBckpDvcIDsBlksMntPointsOnBckpDir_() { #values' order based on VMntedBckpDvcIDsBlksOnBckpDir_
  declare MntedBckpDvcIDsBlkOnBckpDir
  declare -a MntedBckpDvcIDsBlksMntPointsOnBckpDir
  for MntedBckpDvcIDsBlkOnBckpDir in $(VMntedBckpDvcIDsBlksOnBckpDir_); do
    MntedBckpDvcIDsBlksMntPointsOnBckpDir+=($(grep ${MntedBckpDvcIDsBlkOnBckpDir} /proc/mounts | awk '{print $2}'))
  done
  echo ${MntedBckpDvcIDsBlksMntPointsOnBckpDir[@]}
}

VMntedBckpDvcIDsBlksMntPointsOnOtherDir_() {
  declare mntedBckpDvcIDsBlkOnOtherDir_
  declare -a mntedBckpDvcIDsBlksMntPointsOnOtherDir
  for mntedBckpDvcIDsBlkOnOtherDir_ in $(VMntedBckpDvcIDsBlksOnOtherDir_); do
    mntedBckpDvcIDsBlksMntPointsOnOtherDir+=($(grep ${mntedBckpDvcIDsBlkOnOtherDir_} /proc/mounts | awk '{print $2}'))
  done
  echo ${mntedBckpDvcIDsBlksMntPointsOnOtherDir[@]}
}

printBckpDvcConfIDs_() {
  declare bckpDvcID bckpDvcIDsBlk
  echoGreen_ "# List of backup device conf:"
  for bckpDvcID in $(VBckpDvcConfIDs_); do
    if bckpDvcIDsBlk=$(blkid -U ${bckpDvcID} -o device); then
      echo " ID: ${bckpDvcID}, BLK: ${bckpDvcIDsBlk}"
    else
      echo " ID: ${bckpDvcID}, not attached"
    fi
  done
}

printAttchdBckpDvcIDBlks_() { #print attached bckp dvcs' ID & Block
  declare attchdBckpDvcID attchdBckpDvcIDsBlk
  echoGreen_ "# List of attached backup IDs & their blocks:"
  local count=1
  for attchdBckpDvcID in $(VAttchdBckpDvcIDs_); do
    attchdBckpDvcIDsBlk=$(blkid -U ${attchdBckpDvcID} -o device)
    echo " ${count}.ID: ${attchdBckpDvcID}, BLK: ${attchdBckpDvcIDsBlk}"
    ((count+=1))
  done; [[ -z "${attchdBckpDvcID}" ]] && echo "  (null)"
}

printMntedBckpDvcIDBlksAndTheirMntPoints_() {
  declare mntedBckpDvcIDsBlksOnBckpDir
  declare -a mntedBckpDvcIDsBlksMntPointsOnBckpDir
  mntedBckpDvcIDsBlksMntPointsOnBckpDir=($(VMntedBckpDvcIDsBlksMntPointsOnBckpDir_))
  mntedBckpDvcIDsBlksMntPointsOnOtherDir=($(VMntedBckpDvcIDsBlksMntPointsOnOtherDir_))
  echoGreen_ "# List of mounted backup IDs' block & mount point:"
  echo "# On bckup dir:"
  local count=0
  for mntedBckpDvcIDsBlksOnBckpDir in $(VMntedBckpDvcIDsBlksOnBckpDir_); do
    echo " " BLK:${mntedBckpDvcIDsBlksOnBckpDir}, MP:${mntedBckpDvcIDsBlksMntPointsOnBckpDir[$count]}
    ((count+=1))
  done; [[ -z "${mntedBckpDvcIDsBlksOnBckpDir}" ]] && echo "  (null)"
  echo "# On other dirs:"
  local count=0
  for mntedBckpDvcIDsBlkOnOtherDir in $(VMntedBckpDvcIDsBlksOnOtherDir_); do
    echo " " BLK:${mntedBckpDvcIDsBlkOnOtherDir}, MP:${mntedBckpDvcIDsBlksMntPointsOnOtherDir[$count]}
    ((count+=1))
  done; [[ -z "${mntedBckpDvcIDsBlkOnOtherDir}" ]] && echo "  (null)"
}

mountAttchdBckpDvcs_() {
  declare countOfAttchdButUnmntedBckpDvcs
  declare -a attchdBckpDvcIDs mntedBckpDvcIDs mntedBckpDvcIDsBlksMntPointsOnBckpDir attchdButNotMntedBckpDvcIDsBlks
  attchdBckpDvcIDs=($(VAttchdBckpDvcIDs_))
  mntedBckpDvcIDs=($(VMntedBckpDvcIDs_))
  countOfAttchdButUnmntedBckpDvcs=$((${#attchdBckpDvcIDs[@]}-${#mntedBckpDvcIDs[@]})) #check how many dirs are needed to mount
  mntedBckpDvcIDsBlksMntPointsOnBckpDir=($(VMntedBckpDvcIDsBlksMntPointsOnBckpDir_))
  attchdButNotMntedBckpDvcIDsBlks=($(VAttchdButNotMntedBckpDvcIDsBlks_))
  cd $bckpMountDir
  local i count=1
  for ((i=1; i<$((${countOfAttchdButUnmntedBckpDvcs}+1)); i++)); do
    [ -d ${bckpMntSubDirPrfx}${i} ] || sudo_ mkdir ${bckpMntSubDirPrfx}${i}
    #if dir is already mnted, use next dir; add it to be counted for next loop to skip the dir.
    if grep --quiet --no-messages "${bckpMntSubDirPrfx}${i}" <<<"${mntedBckpDvcIDsBlksMntPointsOnBckpDir[@]}"; then
      sudo_ mount ${attchdButNotMntedBckpDvcIDsBlks[$((i-1))]} ${bckpMntSubDirPrfx}$((count+1))
      ((count+=1))
    else
    #else, mnt on dir normally
      sudo_ mount ${attchdButNotMntedBckpDvcIDsBlks[$((i-1))]} ${bckpMntSubDirPrfx}${count}
    fi
    ((count+=1))
  done
  cd - &>/dev/null
}

removeCollisionsInBckpDvcConf_() {
  IFS=' '; echo $(sort "${bckpDvcConf}" | uniq) > ${bckpDvcConf}; unset IFS
}

removeAttchdBckpDvcIDsFromConfAndUnmntIfMnted_() {
  declare IDToRemoveByNum attchdIDToRemove
  declare -a attchdBckpDvcIDs attchdBckpDvcIDsBlks mntedBckpDvcIDsBlksOnBckpDir IDsToRemoveByNums attchdIDsToRemove blksOfattchdIDsToRemove
  attchdBckpDvcIDs=($(VAttchdBckpDvcIDs_))
  attchdBckpDvcIDsBlks=($(VAttchdBckpDvcIDsBlks_))
  mntedBckpDvcIDsBlksOnBckpDir=($(VMntedBckpDvcIDsBlksOnBckpDir_))
  printAttchdBckpDvcIDBlks_
  while read -p "#(PROMPT)IDs to remove(nums): " -a IDsToRemoveByNums; do
    echo "# IDs to remove:"
    for IDToRemoveByNum in ${IDsToRemoveByNums[@]}; do
      echo " BLK:${attchdBckpDvcIDsBlks[$((IDToRemoveByNum-1))]}, ID:${attchdBckpDvcIDs[$((IDToRemoveByNum-1))]}"
    done
    read -n1 -p "#(PROMPT)Correct(y/N)? "; echo
    case $REPLY in
      Y|y) break;;
      *) sleep 0;;
    esac
  done
  for IDToRemoveByNum in ${IDsToRemoveByNums[@]}; do
    attchdIDsToRemove+=(${attchdBckpDvcIDs[$((IDToRemoveByNum-1))]})
    blksOfattchdIDsToRemove+=(${attchdBckpDvcIDsBlks[$((IDToRemoveByNum-1))]})
  done
  echo SS blksOfattchdIDsToRemove ${blksOfattchdIDsToRemove[*]}
  for IDToRemoveByNum in ${IDsToRemoveByNums[@]}; do
    for blkOfattchdIDsToRemove in ${blksOfattchdIDsToRemove[@]}; do
      if grep --quiet --no-messages "${blkOfattchdIDsToRemove}" <<<"${mntedBckpDvcIDsBlksOnBckpDir[@]}"; then
        sudo_ umount --lazy \"$(grep ${blkOfattchdIDsToRemove} /proc/mounts | awk '{print $2}')\"
      fi
    done
  done
  for attchdIDToRemove in ${attchdIDsToRemove[@]}; do
    sed -i "/${attchdIDToRemove}/d" ${bckpDvcConf}
  done
}

addBlkToBckpDvcConf_() {
  declare dvcsToAddInBckpDvcConf dvcToAddInBckpDvcConf IDsOfBlksToAddInBckpDvcConf
  echo "# Device table:"
  lsblk
  cd /dev
  while read -e -p "#(PROMPT)Add devices: " -a dvcsToAddInBckpDvcConf; do
    echo "# Devices to add \"${dvcsToAddInBckpDvcConf[*]}\""
    read -n1 -p "#(PROMPT)Correct(y/N)? "; echo
    case $REPLY in
      Y|y) break;;
      *) sleep 0;;
    esac
  done
  echo "# Asking root passwd for blkid command.."
  until sudo blkid &>/dev/null; do echoRed_ "#!Enter Again!"; done
  for dvcToAddInBckpDvcConf in ${dvcsToAddInBckpDvcConf[@]}; do
    # parse with grep instead of blkid -U, to prevent getting a wrong device, see, wiki page, shell scripting.
    if IDsOfBlksToAddInBckpDvcConf=$(blkid | \grep "/${dvcToAddInBckpDvcConf}:" | \grep -Eo ' UUID="[a-zA-Z0-9]*(-[a-zA-Z0-9]*)*"' | sed -nE 's/ UUID="(.*)"/\1/p'); ! grep --quiet --no-messages "${IDsOfBlksToAddInBckpDvcConf}" $bckpDvcConf; then #Prevent adding exisiting IDs
      echo "${IDsOfBlksToAddInBckpDvcConf}" >> $bckpDvcConf
    fi
  done
  cd - &>/dev/null
}

notAsRoot_
declare -a options
options=(
  "Print all devices' ID in backp device conf"
  "Remove attached backup devices from conf"
  "Add devices to backup device conf"
  "Mount attached backup devices"
  "Exit or Start backup if in a backup script"
  )
while PS3="#(PROMPT)Select: "; echoGreen_ "## Backup Device Management ##"; do
  echoGreen_ "# Asking root privilege for blkid command.."
  # gain root to refresh blkid table every time back to the menu, to prevent using the cached old table.
  until sudo blkid &>/dev/null; do echoRed_ "#!Enter Again!"; done
  removeCollisionsInBckpDvcConf_
  printAttchdBckpDvcIDBlks_
  printMntedBckpDvcIDBlksAndTheirMntPoints_
  echoGreen_ "# Options:"
  IFS=$'\n'; select option in ${options[@]}; do
    unset IFS
    echo
    case $REPLY in
      1) printBckpDvcConfIDs_; break;;
      2) removeAttchdBckpDvcIDsFromConfAndUnmntIfMnted_; printAttchdBckpDvcIDBlks_; break;;
      3) addBlkToBckpDvcConf_; printBckpDvcConfIDs_; break;;
      4) mountAttchdBckpDvcs_; break;;
      5) break 2;;
      *) break;;
    esac
  done; echo
done

