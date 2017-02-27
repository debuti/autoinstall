#!/usr/bin/env bash
################################################################################
#  Author: <a href="mailto:debuti@gmail.com">Borja Garcia</a>
# Program: usermanager raspbian
# Descrip: 
# Version: 0.1.0
#    Date: 20170222
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
while [ -h "$SCRIPT_PATH" ] ; do 
  SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"; 
done
SCRIPT_DIR="$( cd -P "$( dirname "$SCRIPT_PATH" )" && pwd )"
filename=$(basename "$SCRIPT_PATH")
app="${filename%.*}"
extension="${filename##*.}"
INSTALL_TEMP="/tmp/autoinstall.install.$app.tmp"
CONFIG_TEMP="/tmp/autoinstall.config.$app.tmp"

# Aux methods
checkroot() {   
  if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   return -1
  fi
  return 0;  
}
# Archive old configuration files
archiveconf() {
  confpath="$0";
  archiveconfpath="$confpath".old.`date +%Y%m%d.%H%M%S`
  mv "$confpath" "$archiveconfpath"
  return "$archiveconfpath"
}


# Check for other packages needed for installation
checkdependencies() {
  result=0;
  command="expect"
  if ! which $command > /dev/null; then
    echo -e "Dependency not found. Install it by typing"
    echo -e "  sudo apt-get install -y expect"
    result=-1;
  fi   
  return $result;  
}

# Check if already installed
alreadyinstalled() {
  result=0;
  if ! $(which usermanager > /dev/null); then
    result=-1;
  fi   
  return $result;  
}

# Prepare and fetch required data, and save it somewhere
preinstall() {
  result=0;  
  return $result;
}

# Do the installation
doinstall() {
  result=-1;
  cp $SCRIPT_DIR/res/usermanager /usr/local/bin/. && \
  chmod 755 /usr/local/bin/usermanager && \
  result=0
  return $result;
}

# Remove working dir, preinstall files and such
postinstall() { 
  result=0;  
  return $result;
}


# Prepare and fetch required data (ONLY FOR CONFIGURE), and save it somewhere
preconfigure() {
  result=-1; 
  if [[ -f "$CONFIG_TEMP" ]]; then
    return 0
  fi;
  echo -n "" > "$CONFIG_TEMP"

  echo "New admin users"
  while [[ 1 -eq 1 ]]; do
    echo -n 'User (or blank to exit):' && read us
    if [[ -z $us ]]; then
      break; 
    fi;
    echo -n 'Password:' && read password 
    echo makeadmin:$us:$password >> "$CONFIG_TEMP" && echo ""
  done;

  echo "New regular users"
  while [[ 1 -eq 1 ]]; do
    echo -n 'User (or blank to exit):' && read us
    if [[ -z $us ]]; then
      break; 
    fi;
    echo -n 'Password:' && read password 
    echo makeregular:$us:$password >> "$CONFIG_TEMP" && echo ""
  done;

  echo "New jailed users"
  while [[ 1 -eq 1 ]]; do
    echo -n 'User (or blank to exit):' && read us
    if [[ -z $us ]]; then
      break; 
    fi;
    echo -n 'Password:' && read password 
    echo makejailed:$us:$password >> "$CONFIG_TEMP" && echo ""
  done;

  echo "Users to block"
  while [[ 1 -eq 1 ]]; do
    echo -n 'User (or blank to exit):' && read us
    if [[ -z $us ]]; then
      break; 
    fi;
    echo block:$us >> "$CONFIG_TEMP" && echo ""
  done;

  result=0;  
  return $result;
}

# Configure this software
configure() {
  result=-1;
  if [[ ! -f "$CONFIG_TEMP" ]]; then
    echo "Use preinstall first";
    return -1;
  fi;
  while IFS='' read -r line || [[ -n "$line" ]]; do
    action=$(echo "$line" | cut -f1 -d":")
    case $action in
    makeadmin)
      echo makeadmin $(echo "$line" | cut -f2 -d":")
      usermanager make $(echo "$line" | cut -f2 -d":") $(echo "$line" | cut -f3 -d":")
      usermanager enablesudo $(echo "$line" | cut -f2 -d":")
      ;;
    makeregular)
      echo makeregular $(echo "$line" | cut -f2 -d":")
      usermanager make $(echo "$line" | cut -f2 -d":") $(echo "$line" | cut -f3 -d":")
      ;;
    makejailed)
      echo makejailed $(echo "$line" | cut -f2 -d":")
      usermanager make $(echo "$line" | cut -f2 -d":") $(echo "$line" | cut -f3 -d":")
      usermanager enablejail $(echo "$line" | cut -f2 -d":")
      ;;
    block)
      echo block $(echo "$line" | cut -f2 -d":")
      usermanager disable $(echo "$line" | cut -f2 -d":")
      ;;
    *)
      echo "This should never happen"
      return -1;
      ;;
    esac
  done < "$CONFIG_TEMP"
  #Each home folder for its user
  chmod 700 /home/*
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

# Properly uninstall this sw
uninstall() {
  result=-1;
  rm -f /usr/local/bin/usermanager && \
  result=0
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
