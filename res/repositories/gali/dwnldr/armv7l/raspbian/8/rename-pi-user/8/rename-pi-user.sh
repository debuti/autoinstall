#!/usr/bin/env bash
################################################################################
#  Author: <a href="mailto:debuti@gmail.com">Borja Garcia</a>
# Program: rename-pi-user raspbian
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
  return $result;  
}

# Check if already installed
alreadyinstalled() {
  result=0; 
  return $result;  
}

# Prepare and fetch required data, and save it somewhere
preinstall() {
  result=0;  
  return $result;
}

# Do the installation
doinstall() {
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
  echo -n 'What username do you want to replace pi (This will destroy that user home if any)? : ' && read us
  echo -n 'Choose a new password for that user? : ' && read pw
  echo $us:$pw >> "$CONFIG_TEMP" && echo ""
  result=0;  
  return $result;
}

# Configure this software (http://unixetc.co.uk/2016/01/07/how-to-rename-the-default-raspberry-pi-user/)
configure() {
  result=-1;  
  US=$(cat "$CONFIG_TEMP"| cut -f1 -d":")
  PW=$(cat "$CONFIG_TEMP"| cut -f2 -d":")
  if [[ -z $PW ]]; then
    echo "Use preinstall first";
    return -1;
  fi;

  pkill -KILL -u pi  &>/dev/null
  pkill -KILL -u $US  &>/dev/null
  cd /etc
  tar -cvf authfiles-backup.tar passwd group shadow gshadow sudoers lightdm/lightdm.conf systemd/system/autologin@.service sudoers.d/* polkit-1/localauthority.conf.d/60-desktop-policy.conf
  sed -i.$(date +'%y%m%d_%H%M%S') "s/\bpi\b/$US/g" passwd group shadow gshadow sudoers lightdm/lightdm.conf systemd/system/autologin@.service sudoers.d/* polkit-1/localauthority.conf.d/60-desktop-policy.conf
  if [[ -d /home/$US ]]; then
    tar -cvf /tmp/$US-oldhome-backup.tar /home/$US && \
    rm -rf /home/$US
  fi;
  mv /home/pi /home/$US
  ln -s /home/$US /home/pi
  mv /tmp/$US-oldhome-backup.tar /home/$US/. &>/dev/null
  cd -

  echo "spawn passwd $US
      expect \"password:\"
      send \"$PW\r\"
      expect \"password:\"
      send \"$PW\r\"
      expect eof" > /tmp/expect.cmd
  expect -f /tmp/expect.cmd &>/dev/null
  rm /tmp/expect.cmd

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

# Cannot uninstall this sw, reflash the rpi
uninstall() {
  result=-1;  
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
