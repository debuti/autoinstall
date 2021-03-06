#!/usr/bin/env bash
################################################################################
#  Author: <a href="mailto:debuti@gmail.com">Borja Garcia</a>
# Program: x11vnc raspbian
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
  command="xinetd"
  if ! which $command > /dev/null; then
    echo -e "Dependency not found. Install it by typing"
    echo -e "  sudo apt-get install -y xinetd"
    result=-1;
  fi   
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
  if ! which x11vnc > /dev/null; then
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
  apt-get update && \
  apt-get -y install x11vnc && \
  #Config this in the superdaemon
  AUTH=`ps wwaux | grep " -auth" | grep X | sed 's/.*-auth.//g'  | cut -f1 -d" "` && \
  echo "service x11vnc 
    {
            port            = 5900
            type            = UNLISTED
            socket_type     = stream
            protocol        = tcp
            wait            = no
            user            = root
            server          = /usr/bin/x11vnc
            server_args     = -inetd -o /var/log/x11vnc.log -rfbauth /etc/x11vnc.pwd -display :0 -auth $AUTH
            disable         = no
    }" > /etc/xinetd.d/x11vnc && \
  # Estas funciones no van bien en alguna version del x11vnc: server_args = -inetd -o /var/log/x11vnc.log -rfbauth /etc/x11vnc.pwd -display :0 -scale=2/3 -fs=1.0 -once -solid -24to32 -xkb
  /etc/init.d/xinetd restart && \
  result=0
  return $result;
}

# Remove working dir, preinstall files and such
postinstall() {  
  result=0;  
  return $result;
}

# Configure this software
configure() {
  result=-1; 
  PASSWD=$(cat "$CONFIG_TEMP")
  if [[ -z $PASSWD ]]; then
    echo "Use preconfigure first";
    return -1;
  fi;
  echo "spawn x11vnc -storepasswd /etc/x11vnc.pwd
      expect \"something-not-to-be-found\"
      send \"$PASSWD\r\"
      expect \"something-not-to-be-found\"
      send \"$PASSWD\r\"
      expect \"something-not-to-be-found\"
      send \"y\r\"
      expect eof" > /tmp/expect.cmd && \
  expect -f /tmp/expect.cmd && \
  rm /tmp/expect.cmd && \
  chmod 700 /etc/x11vnc.pwd && \
  result=0;  
  return $result;
}

# Prepare and fetch required data (ONLY FOR CONFIGURE), and save it somewhere
preconfigure() {
  result=-1; 
  if [[ -f "$CONFIG_TEMP" ]]; then
    return 0
  fi;
  echo -n "" > "$CONFIG_TEMP" && \
  echo -n 'VNC password: ' && read var && echo $var >> "$CONFIG_TEMP" && \
  echo "" && \
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
  apt-get -y purge x11vnc && \
  apt-get -y clean && \
  apt-get -y autoremove && \
  rm -f /etc/x11vnc.pwd;
  rm -f /etc/xinetd.d/x11vnc;
  /etc/init.d/xinetd restart;
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
