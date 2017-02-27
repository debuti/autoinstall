#!/usr/bin/env bash
################################################################################
#  Author: <a href="mailto:debuti@gmail.com">Borja Garcia</a>
# Program: minidlna raspbian
# Descrip: 
# Version: 0.1.0
#    Date: 20170222
# License: This script doesn't require any license since it's not intended to be
#          redistributed. In such case, unless stated otherwise, the purpose of
#          the author is to follow GPLv3.
# Version history: 
#          0.1.0 (20170222)
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
  # Repeat this foreach dependency 
  command="minidlnad"
  if ! which $command > /dev/null; then
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
  apt-get -y install minidlna && \
  cat > /etc/init/minidlna.conf << EOG
description "Task to start minidlna"

start on (local-filesystems and net-device-up IFACE!=lo)

task

exec service minidlna start

EOG

  #  echo "[Desktop Entry]
  #Encoding=UTF-8
  #Type=Application
  #Name=MiniDLNA
  #Comment=Server to stream media over network
  #Exec=minidlna -f /home/$USER/.minidlna/minidlna.conf -P /home/$USER/.minidlna/minidlna.pid
  #StartupNotify=false
  #Terminal=false
  #Hidden=false" > /home/$USER/.config/autostart/minidlna.desktop && \
  service minidlna start
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
  service minidlna stop
  rm /var/cache/minidlna/*
  MINIDLNA_CONF_FILE="/etc/minidlna.conf"
  MINIDLNA_CONF_FILE_OLD=$MINIDLNA_CONF_FILE.$(date +%Y%m%d-%H%M%S)
  cp $MINIDLNA_CONF_FILE $MINIDLNA_CONF_FILE_OLD
  cat $MINIDLNA_CONF_FILE_OLD | 
  sed 's/^media_dir.*/media_dir=V,\/media\/hd_media\/Media\/Videos\nmedia_dir=V,\/media\/hd_media\/Queues/g' |  
  sed 's/.*log_level.*/log_level=general,database,inotify,scanner=info,metadata,http,ssdp,tivo,artwork=warn/g' |  
  sed 's/^#friendly_name.*/friendly_name=videoclub/g' | 
  sed 's/.*notify_interval.*/notify_interval=300/g' | 
  sed 's/^#db_dir.*/db_dir=\/var\/cache\/minidlna/g' | 
  sed 's/^#log_dir.*/log_dir=\/var\/log/g' | 
  sed 's/^#inotify.*/inotify=yes/g' | 
  sed 's/^#root_container.*/root_container=./g' > $MINIDLNA_CONF_FILE
  if [[ -z $(grep max_user_watches /etc/sysctl.conf) ]]; then
    echo "fs.inotify.max_user_watches=999999999"  >> /etc/sysctl.conf
  fi;
  # Reload every morning to ensure everythings alright
  crontab -l > /tmp/tmp.crontab
  echo "
0 6  *  *  *  /usr/sbin/service minidlna force-reload
" >> /tmp/tmp.crontab && \
  crontab /tmp/tmp.crontab && \
  rm /tmp/tmp.crontab

  service minidlna force-reload
  result=0;  
  return $result;
}

# Prepare and fetch required data (ONLY FOR CONFIGURE), and save it somewhere
preconfigure() {
  result=0;  
  return $result;
}

# Remove working dir, preconfigure files and such
postconfigure() {  
  result=0;  
  return $result;
}

# Properly uninstall this sw
uninstall() {
  result=-1; 
  apt-get -y purge minidlna && \
  apt-get -y clean && \
  apt-get -y autoremove && \
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
