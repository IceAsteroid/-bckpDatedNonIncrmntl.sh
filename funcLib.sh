print_line_() { #Print a line strung with - .
  local var1=0
  local var2=$(tput cols)
  for (( i=0; i<$var2; i++)) {
   echo -n "="
  }
  echo
}

echoRed_() {
  echo -e "\x1B[31m$*\x1B[0m"
}

echoGreen_() {
  echo -e "\x1B[32m$*\x1B[0m"
}

confirm_to_continue_() { #Confirm before a command runs, if N is entered, script exits.
  local ask_to_continue
  while read -n1 -p "$1 " ask_to_continue; do
    echo
    case $ask_to_continue in
      Y|y)  break;;
      N|n)  exit;;
      *)  echo "Enter only Y/y or N/n!";;
    esac
  done
}

confirm_to_loop_(){
  declare ask_to_loop # for local use
  read -n1 -p "#(PROMPT)Retry(Y/n)? " ask_to_loop; echo
  case $ask_to_loop in
  Y|y)sleep 0;;
  *)  exit 2;;
  esac
}

sudo_(){
  if [ "$USER" != "root" ]; then
    echo "# Passwd is required to run \"$@\""
    sudo "$@"
  else
    eval "$@"
  fi
}

sudoNoHint_(){
  if [ "$USER" != "root" ]; then
    sudo "$@"
  else
    eval "$@"
  fi
}

notAsRoot_(){
  [ "$USER" = root ] && eval 'echo "#!Do Not Run As Root For V2ray! Script Exits"; exit'
}

if touch /tmp/terminalPWD.txt; then
  chmod 660 /tmp/terminalPWD.txt 
  cd_() { #it's named instead of cd to prevent the func called by 'cd' inside of ohter scripts
          #store pwd of terminal and be used for window manager to open terminal on that directory with a shortcut
          # "command" prevents recalling the func recursively by calling the actuall builtin cd command
    command cd ${1} && pwd > /tmp/terminalPWD.txt || return 2
  }
  VGetLastCdDir_() {
      cat /tmp/terminalPWD.txt
  }
else
  echoRed_ "#!cd_ function isnt loaded!"
fi









