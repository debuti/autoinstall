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
  if [[ ! -d /var/lib/tomcat8 ]]; then
    echo -e "Dependency not found. Install it by typing"
    echo -e "  sudo apt-get install -y tomcat8"
    result=-1;
  fi   
  return $result;  
}

# Check if already installed
alreadyinstalled() {
  result=0;
  if [[ ! -f /etc/guacamole/guacamole.properties ]]; then
    echo "Not installed"
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
  apt-get -y install libguac5  && \
  apt-get -y install libguac-client-vnc0 && \
  apt-get -y install libguac-client-ssh0 && \
  apt-get -y install libguac-client-rdp0 && \
  apt-get -y install guacd && \
  apt-get -y install guacamole && \
  ln -s /var/lib/guacamole/guacamole.war /var/lib/tomcat8/webapps && \
  ln -s /etc/guacamole/guacamole.properties /usr/share/tomcat8/lib && \
  result=0;  
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
  US=$(cat "$CONFIG_TEMP"| cut -f1 -d":")
  PW=$(cat "$CONFIG_TEMP"| cut -f2 -d":")
  VNCPW=$(cat "$CONFIG_TEMP"| cut -f3 -d":")
  if [[ -z $PW ]]; then
    echo "Use preconfigure first";
    return -1;
  fi;

  GUACA_USER_FILE="/etc/guacamole/user-mapping.xml"
  cp $GUACA_USER_FILE $GUACA_USER_FILE.$(date +%Y%m%d-%H%M%S)
  cat > $GUACA_USER_FILE << EOG
<user-mapping>
    <authorize
            username="$US"
            password="$(echo -n $PW | md5sum | cut -f1 -d" ")"
            encoding="md5">
        <connection name="ssh">
            <protocol>ssh</protocol>
            <param name="hostname">localhost</param>
            <param name="port">22</param>
        </connection>
        <connection name="vnc">
            <protocol>vnc</protocol>
            <param name="hostname">localhost</param>
            <param name="port">5900</param>
            <!-- Not supported by guacamole param name="color-depth">8</param-->
            <param name="password">$VNCPW</param>
        </connection>
    </authorize>
</user-mapping>
EOG
  chmod 700 $GUACA_USER_FILE
  chown tomcat8:tomcat8 $GUACA_USER_FILE
  service tomcat8 restart
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
  echo -n 'Guacamole user: ' && read us
  echo -n 'Guacamole password: ' && read password 
  echo -n 'VNC password: ' && read vncpassword 
  echo $us:$password:$vncpassword >> "$CONFIG_TEMP" && echo ""
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
  apt-get -y purge guacd guacamole libguac* && \
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
