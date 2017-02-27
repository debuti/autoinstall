#!/usr/bin/env bash
################################################################################
#  Author: <a href="mailto:debuti@gmail.com">Borja Garcia</a>
# Program: vsftpd raspbian
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
  if [[ `ls -1 /etc/vsftpd.conf* | wc -l` -eq  0 ]]; then
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
  apt-get -y install vsftpd && \
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
  # Permit /bin/false shell users to login to the ftp server
  if [[ -z $(grep "^/bin/false$" /etc/shells) ]]; then
    echo "/bin/false" >> /etc/shells
  fi;
  FTP_PROPERTIES_FILE="/etc/vsftpd.conf"
  BACKUP_PROPERTIES_FILE=$FTP_PROPERTIES_FILE.$(date +%Y%m%d.%H%M%S)
  cp $FTP_PROPERTIES_FILE $BACKUP_PROPERTIES_FILE
  cat $BACKUP_PROPERTIES_FILE | 
  sed "s/anonymous_enable=.*/anonymous_enable=NO/g" | 
  sed "s/#local_enable.*/local_enable=YES/g" | 
  sed "s/#write_enable.*/write_enable=YES/g" |
  sed "s/#chroot_local_user.*/chroot_local_user=YES/g" | 
  sed "s/#chroot_list_enable.*/chroot_list_enable=YES/g" | 
  sed "s/#chroot_list_file.*/chroot_list_file=\/etc\/vsftpd.chroot_list/g" | 
  sed "s/#ftpd_banner=.*/ftpd_banner=Private FTP Server/g" > $FTP_PROPERTIES_FILE
  echo "allow_writeable_chroot=YES" >> $FTP_PROPERTIES_FILE
  # Los que entran en el fichero de chroot son los que NO quedan restringidos a su casa
  touch /etc/vsftpd.chroot_list
  /etc/init.d/vsftpd restart
  result=0
  return $result;
}

# Properly uninstall this sw
uninstall() {
  result=-1;
  FTP_PROPERTIES_FILE="/etc/vsftpd.conf"
  BACKUP_PROPERTIES_FILE=$FTP_PROPERTIES_FILE.$(date +%Y%m%d.%H%M%S)
  cp $FTP_PROPERTIES_FILE $BACKUP_PROPERTIES_FILE
  apt-get -y purge vsftpd && \
  apt-get -y clean && \
  apt-get -y autoremove && \
  result=0
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
