#!/usr/bin/env bash
################################################################################
#  Author: <a href="mailto:debuti@gmail.com">Borja Garcia</a>
# Program: autoinstall
# Descrip: 
# Version: 0.1.1
#    Date: 20170222
# License: This script doesn't require any license since it's not intended to be
#          redistributed. In such case, unless stated otherwise, the purpose of
#          the author is to follow GPLv3.
# Version history:
#          0.1.1 (20180315)
#           - Added custom commands: reboot, message and messagewait
#          0.0.0 (20170222)
#           - Initial release
################################################################################

# Check for root
if [[ $EUID -ne 0 ]]; then
 echo "This script must be run as root" 1>&2
 exit -1
fi

# Parameters
DATE=`date +%Y%m%d`
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [ -h "$SCRIPT_PATH" ] ; do 
  SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"; 
done
SCRIPT_DIR="$( cd -P "$( dirname "$SCRIPT_PATH" )" && pwd )"
LOG_PATH="$(readlink -f "$SCRIPT_DIR/../log")"

# Constants
columns=$(tput cols)
alias txtgrn='tput setaf 2' # Green
alias txtpur='tput setaf 5' # Purple
alias txtrst='tput sgr0'    # Text reset.
col1=$(echo $columns*0.8 / 1|bc 2>/dev/null || awk "BEGIN {printf \"%.0f\n\", $columns*0.8 / 1}" || echo 50)
col2=$(echo $columns-$col1|bc 2>/dev/null   || awk "BEGIN {printf \"%.0f\n\", $columns-$col1}"   || echo 50)


# Global variables
log="$LOG_PATH/$DATE.log"
config_file=""
stop_if_failed="Unchecked"
dry="Unchecked"
verbose="Unchecked"


# Error codes
NOERROR=0;
ERROR_PREINSTALL_FAILED=-10;
ERROR_ALREADY_INSTALLED=-20;
ERROR_DEPENDENCIES_MISSING=-30;
ERROR_NOROOT=-35;
ERROR_INSTALL_FAILED=-40;
ERROR_POSTINSTALL_FAILED=-50;        
ERROR_PRECONFIGURE_FAILED=-60;     
ERROR_CONFIGURE_FAILED=-70;     
ERROR_POSTCONFIGURE_FAILED=-80;
ERROR_UNINSTALL_FAILED=-90;
ERROR_REINSTALL_FAILED=-100;


# Usage function
function usage() {
  # Tell the user how to use me
  echo -e "$0 [Options] <config_file>"
  echo -e "\tOptions:"
  echo -e "\t\t-s\tStop if one action fails"
  echo -e "\t\t-d\tDry run"
  echo -e "\t\t-v\tBe more verbose"
  
  echo "Last modification time:" `stat -c %y $SCRIPT_PATH`
}

# Input validation function (getopts)
function checkInput() {
  mandatory=0
  while getopts ":s:d:v" opt; do
    case $opt in
      s)
        stop_if_failed="Checked";
        ;;
      d)
        dry="Checked";
        ;;
      v)
        verbose="Checked";
        ;;
      \?)  #Default
        echo "Option not recognized"
        usage $0
        exit -1
        ;;
       :)
        echo "Option -$OPTARG requires an argument." >&2
        exit -1
        ;;
    esac
  done
  
  #Go to arguments
  shift `expr $OPTIND - 1`
  
  #Check arguments length and mandatory options
  if [ $# -ne 1 ]; then
    echo "Recognized $# arguments"
    usage $0
    exit -1
  else
    config_file="${1}"
    return 0
  fi 
}

# Dependencies validation
function checkDependencies() {
  return 0
}


# Log functions
function openLog() {
  mkdir $LOG_PATH 2> /dev/null
  exec 3>&1 > >(tee -a "$log")     # Save current stdout to file descriptor 3, and redirect stdout to tee
}

function closeLog() {
  exec 1>&3 3>&-                   # Restore stdout and close file descriptor 3 before we exit
}

function closeLogNexit() {
  closeLog && exit $1
}


# Helper functions
  
  
# Main function
function main() {
  if [[ $verbose == "Checked" ]]; then 
    echo "Running in $columns columns wide, first one to $col1, second one to $col2"
  fi
 
# Otra manera de qno se le haga la picha un lio
#while read -u 3 item
#do
  # other stuff
#  read -p "choose wisely: " choice
  # other stuff
#done 3< /tmp/item.list

  readarray -t lines <<< "$(cat $config_file | grep -v \^s*\# | grep -v ^\s*$)"

  # Retrieve needed info
  echo "Retrieving info:"
  for rawline in "${lines[@]}"; do
    line=`echo $rawline |sed -e "s/[[:space:]]\+/|/g"`
    system=`echo $line|cut -f1 -d"|"`
    arq=`echo $line|cut -f2 -d"|"`
    os=`echo $line|cut -f3 -d"|"`
    osversion=`echo $line|cut -f4 -d"|"`
    app=`echo $line|cut -f5 -d"|"`
    version=`echo $line|cut -f6 -d"|"`
    action=`echo $line|cut -f7 -d"|"`

    if [[ $line == "reboot" ]]; then
      continue;
    fi;

    if [[ $action == "install" ]]; then 
      action="preinstall"
    elif [[ $action == "configure" ]]; then 
      action="preconfigure"
    else
      continue
    fi;

    installerPath=`readlink -f $config_file | xargs dirname | xargs find | grep /$arq/ | grep /$os/$osversion/ | grep /$app/$version/ | grep /$app.sh$ | head 
-1`
    
    if [[ -z "$installerPath" ]]; then
      printf "%-${col1}s%-${col2}s\n" "System:$system Arq:$arq OS:$os OSver:$osversion App:$app v:$version Action:$action" "$(tput setaf 5)[FAIL] I cant found
 install file$(tput sgr0)"
      return -1;
    else 
      if [[ $dry == "Checked" ]]; then 
        printf "%-${col1}s%-${col2}s\n" "Would run $installerPath $action" "$(tput setaf 2)[OK]$(tput sgr0)"
        #echo "Would run $installerPath $action"
        continue
      else
        printf "%-${col1}s\n" "$installerPath $action"
        chmod u+x $installerPath
        bash $installerPath $action
      fi
      if [[ $? -ne 0 ]]; then
        printf "%-${col1}s%-${col2}s\n" "System:$system Arq:$arq OS:$os OSver:$osversion App:$app v:$version Action:$action" "$(tput setaf 5)[FAIL]$(tput sgr0
)"
        if [[ $stop_if_failed == "Checked" ]]; then 
          printf "Check your logs $stdout and $stderr"
          return -1;
        fi
      fi
    fi
  done

  # Do actions
  echo "Applying actions:"
  for rawline in "${lines[@]}"; do
    line=`echo $rawline |sed -e "s/[[:space:]]\+/|/g"`
    system=`echo $line|cut -f1 -d"|"`
    arq=`echo $line|cut -f2 -d"|"`
    os=`echo $line|cut -f3 -d"|"`
    osversion=`echo $line|cut -f4 -d"|"`
    app=`echo $line|cut -f5 -d"|"`
    version=`echo $line|cut -f6 -d"|"`
    action=`echo $line|cut -f7 -d"|"`

    if [[ ! -z $(echo $rawline | egrep "^reboot") ]]; then
      echo "Rebooting in 10 seconds";
      sleep 10;
      reboot now;
    fi;
    if [[ ! -z $(echo $rawline | egrep "^messagewait")  ]]; then
      msg=$(echo $rawline | sed 's/^message\w* //g' |sed 's/"//g') 
      echo "$msg"
      read -n1 -r -p "Press space to continue..." key
      continue
    fi;
    if [[ ! -z $(echo $rawline | egrep "^message") ]]; then
      msg=$(echo $rawline | sed 's/^message\w* //g' |sed 's/"//g') 
      echo "$msg"
      continue
    fi;

    stdout="$LOG_PATH/$DATE.$app.out"
    stderr="$LOG_PATH/$DATE.$app.err"
 
    installerPath=`readlink -f $config_file | xargs dirname | xargs find | grep /$arq/ | grep /$os/$osversion/ | grep /$app/$version/ | grep /$app.sh$ | head 
-1`
    
    if [[ -z "$installerPath" ]]; then
      printf "%-${col1}s%s\n" "System:$system Arq:$arq OS:$os OSver:$osversion App:$app v:$version Action:$action" "$(tput setaf 5)[FAIL] I cant found install
 file$(tput sgr0)"
      return -1;
    else 
      LAST_OUTPUT_STATUS=0
      if [[ $dry == "Checked" ]]; then 
        printf "%-${col1}s%s\n" "Would run $installerPath $action" "$(tput setaf 2)[OK]$(tput sgr0)"
        continue
      else
        printf "%-${col1}s" "System:$system Arq:$arq OS:$os OSver:$osversion App:$app v:$version Action:$action"
        bash $installerPath $action > $stdout 2> $stderr
        LAST_OUTPUT_STATUS=$?
      fi

      if [[ $LAST_OUTPUT_STATUS -eq $NOERROR ]]; then
        printf "\r%-${col1}s%s\n" "System:$system Arq:$arq OS:$os OSver:$osversion App:$app v:$version Action:$action" "$(tput setaf 2)[OK]$(tput sgr0)"
      else
        printf "\r%-${col1}s%s" "System:$system Arq:$arq OS:$os OSver:$osversion App:$app v:$version Action:$action" "$(tput setaf 5)[FAIL]$(tput sgr0)"
        if [[ $LAST_OUTPUT_STATUS -eq $ERROR_PREINSTALL_FAILED ]]; then
          printf "%s\n" "$(tput setaf 5)Preinstall failed$(tput sgr0)"
        elif [[ $LAST_OUTPUT_STATUS -eq $ERROR_ALREADY_INSTALLED ]]; then
          printf "%s\n" "$(tput setaf 5)App already installed$(tput sgr0)"
        elif [[ $LAST_OUTPUT_STATUS -eq $ERROR_DEPENDENCIES_MISSING ]]; then
          printf "%s\n" "$(tput setaf 5)Dependencies are missing$(tput sgr0)"
        elif [[ $LAST_OUTPUT_STATUS -eq $ERROR_NOROOT ]]; then
          printf "%s\n" "$(tput setaf 5)Root needed$(tput sgr0)"
         elif [[ $LAST_OUTPUT_STATUS -eq $ERROR_INSTALL_FAILED ]]; then
          printf "%s\n" "$(tput setaf 5)Install failed$(tput sgr0)"
        elif [[ $LAST_OUTPUT_STATUS -eq $ERROR_POSTINSTALL_FAILED ]]; then
          printf "%s\n" "$(tput setaf 5)Postinstall failed$(tput sgr0)"
        elif [[ $LAST_OUTPUT_STATUS -eq $ERROR_PRECONFIGURE_FAILED ]]; then
          printf "%s\n" "$(tput setaf 5)Preconfigure failed$(tput sgr0)"
         elif [[ $LAST_OUTPUT_STATUS -eq ERROR_CONFIGURE_FAILED ]]; then
          printf "%s\n" "$(tput setaf 5)Configure failed$(tput sgr0)"
        elif [[ $LAST_OUTPUT_STATUS -eq $ERROR_POSTCONFIGURE_FAILED ]]; then
          printf "%s\n" "$(tput setaf 5)Postconfigure failed$(tput sgr0)"
        elif [[ $LAST_OUTPUT_STATUS -eq $ERROR_UNINSTALL_FAILED ]]; then
          printf "%s\n" "$(tput setaf 5)Uninstall failed$(tput sgr0)"
         elif [[ $LAST_OUTPUT_STATUS -eq $ERROR_REINSTALL_FAILED ]]; then
          printf "%s\n" "$(tput setaf 5)Reinstall failed$(tput sgr0)"
         else
          printf "%s\n" "$(tput setaf 5)Unknown error: $LAST_OUTPUT_STATUS $(tput sgr0)"
        fi
        if [[ stop_if_failed == "Checked" ]]; then 
          printf "Check your logs $stdout and $stderr"
          return -1;
        fi
      fi
    fi
  done

  return 0
}


# Entry point
checkDependencies
checkInput "$@"
openLog
main
exit_code=$?
closeLog
exit $exit_code
