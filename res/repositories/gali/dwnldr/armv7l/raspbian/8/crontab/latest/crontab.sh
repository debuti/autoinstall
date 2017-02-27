#!/usr/bin/env bash
################################################################################
#  Author: <a href="mailto:debuti@gmail.com">Borja Garcia</a>
# Program: crontab raspbian
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
  if [[ ! -z $(crontab -l 2>/dev/null | grep ejecutado) ]]; then
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
  crontab -l > /tmp/tmp.crontab
  echo "
#.---------------- minuto (0 - 59) 
#|  .------------- hora (0 - 23)
#|  |  .---------- dia del mes (1 - 31)
#|  |  |  .------- mes (1 - 12) O jan,feb,mar,apr ... (los meses en ingles)
#|  |  |  |  .---- dia de la semana (0 - 6) (Domingo=0 a 7) O sun,mon,tue,wed,thu,fri,sat (los dias en ingles) 
#|  |  |  |  |
#*  *  *  *  *  comando para ser ejecutado
" | cat - /tmp/tmp.crontab > /tmp/tmp.crontab.temp && \
  mv /tmp/tmp.crontab.temp /tmp/tmp.crontab && \
  crontab /tmp/tmp.crontab && \
  rm /tmp/tmp.crontab && \
  result=0;  
  return $result;
}

# Properly uninstall this sw. Cant
uninstall() {
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
