#!/usr/bin/env bash
################################################################################
#  Author: <a href="mailto:debuti@gmail.com">Borja Garcia</a>
# Program: tomcat raspbian
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
  if [[ `ls -1 /etc/default/tomcat8 | wc -l` -eq  0 ]]; then
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
  apt-get -y install tomcat8 && \
  apt-get -y install tomcat8-admin && \
  result=0;  
  return $result;
}

# Remove working dir, preinstall files and such
postinstall() {  
  result=0;  
  return $result;
}

preconfigure() {
  result=-1; 
  if [[ -f "$CONFIG_TEMP" ]]; then
    return 0
  fi;
  echo -n "" > "$CONFIG_TEMP" && \
  echo -n 'Tomcat Manager user: ' && read us
  echo -n 'Tomcat Manager password: ' && read password 
  echo $us:$password >> "$CONFIG_TEMP" && echo ""
  result=0;  
  return $result;
}

# Configure this software
configure() {
  result=-1; 
  US=$(cat "$CONFIG_TEMP"| cut -f1 -d":")
  PW=$(cat "$CONFIG_TEMP"| cut -f2 -d":")
  if [[ -z $PW ]]; then
    echo "Use preconfigure first";
    return -1;
  fi;

  TOMCAT_USER_FILE="/etc/tomcat8/tomcat-users.xml"
  cp $TOMCAT_USER_FILE $TOMCAT_USER_FILE.$(date +%Y%m%d-%H%M%S)
  cat > $TOMCAT_USER_FILE << EOG
<?xml version='1.0' encoding='utf-8'?> 
<tomcat-users>  
    <role rolename="admin-gui"/>
    <role rolename="admin-script"/>
    <role rolename="manager-gui"/>
    <role rolename="manager-script"/>
    <role rolename="manager-jmx"/>
    <role rolename="manager-status"/>
    <user username="$US" password="$PW" roles="manager-gui,manager-script,manager-jmx,manager-status,admin-gui,admin-script"/> 
</tomcat-users>
EOG

  cat > /var/lib/tomcat8/webapps/ROOT/index.html << EOG
<html>
  <iframe style="border: 0; width: 100%; height: 100%" frameborder='0' src='https://docs.google.com/spreadsheet/pub?key=0ArM5yzzCw9IZdEk2NW4zRkJLNXZlanB1cG1DaHNMLWc&output=html&widget=true'></iframe>
</html>
EOG

  chmod 700 $TOMCAT_USER_FILE
  chown tomcat8:tomcat8 $TOMCAT_USER_FILE
  service tomcat8 restart
  rm -f "$CONFIG_TEMP"
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
  service tomcat8 stop
  apt-get -y purge tomcat8* && \
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
