#!/usr/bin/env bash
################################################################################
#  Author: <a href="mailto:debuti@gmail.com">Borja Garcia</a>
# Program: installall. Installation package
# Descrip: 
# Version: 0.1.0
#    Date: 20141031
# License: This script doesn't require any license since it's not intended to be
#          redistributed. In such case, unless stated otherwise, the purpose of
#          the author is to follow GPLv3.
# Version history: 
#          0.1.0 (20141031)
#           - Initial release
################################################################################

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


# Globals
SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_NAME=$SCRIPT_PATH
filename=$(basename "$SCRIPT_PATH")
app="${filename%.*}"
extension="${filename##*.}"
INSTALL_TEMP="/tmp/autoinstall.install.$app.tmp"
CONFIG_TEMP="/tmp/autoinstall.config.$app.tmp"

checkroot() {   
  if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   return -1
  fi
  return 0;  
}

# Check for other packages needed for installation
checkdependencies() {
  result=0;
  return $result;  
}

# Check if already installed
alreadyinstalled() {
  result=0;
  # Repeat this foreach dependency 
  command=""
  if [ ! -z "`grep remove-source-files /root/.bashrc`" ]; then
    result=-1;
  fi   
  return $result;  
}

# Prepare and fetch required data, and save it somewhere
preinstall() {
  echo "" > "$CONFIG_TEMP"
  echo 'Insert username for installing this program:' && read var && echo "username=$var" >> "$CONFIG_TEMP"
  return 0;
}

installaliases() {
  #http://www.marksanborn.net/linux/creating-useful-bash-aliases/
  path=$1
  user=$2
  echo 'alias smv="rsync --remove-source-files -varP"'  >>$path/.bashrc
  echo 'alias rsynccopy="rsync --partial --progress --append --rsh=ssh -r -h "' >> $path/.bashrc
  echo 'tmv() { rsync -varp "$1" "$2" && rm -rf "$1";}' >> $path/.bashrc
  echo 'alias rsyncmove="rsync --partial --progress --append --rsh=ssh -r -h --remove-sent-files"' >> $path/.bashrc
  echo 'alias psx="ps -auxw | grep $1"' >>$path/.bashrc
  echo 'alias psme="ps -Af | grep $USER"' >>$path/.bashrc
  echo 'alias psname="ps -Af | grep $1"' >>$path/.bashrc
  echo 'alias psport="lsof -i | grep $1"' >>$path/.bashrc
  echo 'alias ..="cd .."' >> $path/.bashrc
  echo 'alias ...="cd ../.."' >> $path/.bashrc
  echo 'alias ....="cd ../../.."' >> $path/.bashrc
  echo 'alias .....="cd ../../../.."' >> $path/.bashrc
  echo 'alias ..="cd .."' >> $path/.bashrc
  echo 'alias ..2="cd ../.."' >> $path/.bashrc
  echo 'alias ..3="cd ../../.."' >> $path/.bashrc
  echo 'alias ..4="cd ../../../.."' >> $path/.bashrc
  echo 'alias ll="ls -la"' >> $path/.bashrc
  echo 'alias dfh="df -h"' >> $path/.bashrc
  echo 'alias transmission-remote="transmission-remote --auth $USER:$PWD"' >> $path/.bashrc
  echo 'function cdl { cd $1; ls;}' >> $path/.bashrc
  echo 'last() { history | tail -2 | head -1 | sed "s|\s*\w*\s*||"; }' >> $path/.bashrc
  #echo 'alias xargscomma="sed "s/\'/\\\\\\'/g" | xargs"' >> $path/.bashrc
  #echo 'alias codename="lsb_release -c | sed \'s/\w*:\s*//g\\'"' >> $path/.bashrc
}

# Do the installation
doinstall() {
  result=-1;

  username=`cat "$CONFIG_TEMP" | grep "username=" | sed -s 's/username=//g'`

  installaliases "/root/" "root" && \
  installaliases "/home/$username" "$username" && \
  result=0
  return $result;
}

# Remove working dir, preinstall files and such
postinstall() {  
  if [[ -f "$CONFIG_TEMP" ]]; then rm "$CONFIG_TEMP"; fi;
  
  # If any temporary files like downloads or so, remove them here
  return 0;
}

# Configure this software
configure() {
  return 0;
}

# Properly uninstall this sw
uninstall() {
  return 0;
}

# Prepare and fetch required data (ONLY FOR CONFIGURE), and save it somewhere
preconfigure() {
  result=0;  
  return $result;
}

# Remove working dir, preconfigure files and such
postconfigure() {  
  if [[ -f "$CONFIG_TEMP" ]]; then 
    rm "$CONFIG_TEMP"; 
  fi;
  result=0;  
  return $result;
}



# Usage
usage() {
  echo "$0 [setup|preinstall|install|preconfigure|configure|uninstall|reinstall]"
}

(checkroot || exit $ERROR_NOROOT)

#Entry point
case $1 in
    setup)
        (! alreadyinstalled || exit $ERROR_ALREADY_INSTALLED) && \
        (checkdependencies || exit $ERROR_DEPENDENCIES_MISSING) && \
        (preinstall || exit $ERROR_PREINSTALL_FAILED) && \
        (preconfigure || exit $ERROR_PRECONFIGURE_FAILED) && \
        (doinstall || exit $ERROR_INSTALL_FAILED) && \
        (postinstall || exit $ERROR_POSTINSTALL_FAILED) && \
        (configure || exit $ERROR_CONFIGURE_FAILED) && \
        (postconfigure || exit $ERROR_POSTCONFIGURE_FAILED) && \
        exit $NOERROR;
        ;;
    preinstall)
        (preinstall || exit $ERROR_PREINSTALL_FAILED) && \
        exit $NOERROR;
        ;;
    install)
        (! alreadyinstalled || exit $ERROR_ALREADY_INSTALLED) && \
        (checkdependencies || exit $ERROR_DEPENDENCIES_MISSING) && \
        (preinstall || exit $ERROR_PREINSTALL_FAILED) && \
        (doinstall || exit $ERROR_INSTALL_FAILED) && \
        (postinstall || exit $ERROR_POSTINSTALL_FAILED) && \
        exit $NOERROR;
        ;;
    preconfigure)
        (preconfigure || exit $ERROR_PRECONFIGURE_FAILED) && \
        exit $NOERROR;
        ;;
    configure)
        (alreadyinstalled || exit $ERROR_ALREADY_INSTALLED) && \
        (preconfigure || exit $ERROR_PRECONFIGURE_FAILED) && \
        (configure || exit $ERROR_CONFIGURE_FAILED) && \
        (postconfigure || exit $ERROR_POSTCONFIGURE_FAILED) && \
        exit $NOERROR;
        ;;
    uninstall)
        (alreadyinstalled || exit $ERROR_ALREADY_INSTALLED) && \
        (uninstall || exit $ERROR_UNINSTALL_FAILED) && \
        exit $NOERROR;
        ;;
    reinstall)
        (alreadyinstalled || exit $ERROR_ALREADY_INSTALLED) && \
        (uninstall || exit $ERROR_UNINSTALL_FAILED)
        (! alreadyinstalled || exit $ERROR_ALREADY_INSTALLED) && \
        (checkdependencies || exit $ERROR_DEPENDENCIES_MISSING) && \
        (preinstall || exit $ERROR_PREINSTALL_FAILED) && \
        (preconfigure || exit $ERROR_PRECONFIGURE_FAILED) && \
        (doinstall || exit $ERROR_INSTALL_FAILED) && \
        (postinstall || exit $ERROR_POSTINSTALL_FAILED) && \
        (configure || exit $ERROR_CONFIGURE_FAILED) && \
        (postconfigure || exit $ERROR_POSTCONFIGURE_FAILED) && \
        exit $NOERROR;
        ;;
    *)
        usage && exit -1;
        ;;
esac
