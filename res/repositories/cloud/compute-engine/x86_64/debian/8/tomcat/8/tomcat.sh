#!/usr/bin/env bash
################################################################################
#  Author: <a href="mailto:debuti@gmail.com">Borja Garcia</a>
# Program: tomcat debian
# Descrip: 
# Version: 0.1.0
#    Date: 20170324
# License: This script doesn't require any license since it's not intended to be
#          redistributed. In such case, unless stated otherwise, the purpose of
#          the author is to follow GPLv3.
# Version history: 
#          0.1.0 (20170324)
#           - Initial release
################################################################################

#TODO: Server.xml config 


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
  result=-1;
  if [[ -f /etc/default/tomcat8 ]]; then
    result=0;
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
  echo -n 'HTTPS cert pwd: ' && read certpassword 
  echo "$us:$password:$certpassword" >> "$CONFIG_TEMP" && echo ""
  result=0;  
	  rplittedaa << EOG
turn $result;
}

# Configure this software
configure() {
  result=-1; 
  US=$(cat "$CONFIG_TEMP"| cut -f1 -d":")
  PW=$(cat "$CONFIG_TEMP"| cut -f2 -d":")
  CERTPW=$(cat "$CONFIG_TEMP"| cut -f3 -d":")
  if [[ -z $PW ]]; then
    echo "Use preconfigure first";
    return -1;
  fi;

  for i in 80 443; do
    touch /etc/authbind/byport/$i
    chmod 500 /etc/authbind/byport/$i
    chown tomcat8:tomcat8 /etc/authbind/byport/$i
  done

  TOMCAT_DEFAULT_FILE="/etc/default/tomcat8"
  OLD_TOMCAT_DEFAULT_FILE=$TOMCAT_DEFAULT_FILE.$(date +%Y%m%d-%H%M%S)
  cp $TOMCAT_DEFAULT_FILE $OLD_TOMCAT_DEFAULT_FILE
  cat $OLD_TOMCAT_DEFAULT_FILE | 
  sed "s/^#AUTHBIND=no$/AUTHBIND=yes/g" > $TOMCAT_DEFAULT_FILE


  TOMCAT_CONF_FILE="/etc/tomcat8/server.xml"
  OLD_TOMCAT_CONF_FILE=$TOMCAT_CONF_FILE.$(date +%Y%m%d-%H%M%S)
  cp $TOMCAT_CONF_FILE $OLD_TOMCAT_CONF_FILE
  cat $OLD_TOMCAT_CONF_FILE |perl -0pe 's/<!--.*?-->//sg' | sed '/^\s*$/d' > $TOMCAT_CONF_FILE.tmp
  cat $TOMCAT_CONF_FILE.tmp |
  sed "s/\"8080\"/\"80\"/g" |
  sed "s/\"8443\"/\"443\"/g" > $TOMCAT_CONF_FILE.tmp2
  SPLIT_LINE=$(cat $TOMCAT_CONF_FILE.tmp2 | grep Connector -n | cut -f1 -d":")
  SPLIT_LINE=$(($SPLIT_LINE-1))
  echo "Will split by $SPLIT_LINE"
  split -l$SPLIT_LINE $TOMCAT_CONF_FILE.tmp2 splitted
  cat >> splittedaa << EOG
<Connector port="443" protocol="org.apache.coyote.http11.Http11NioProtocol"
 maxThreads="150" SSLEnabled="true" scheme="https" secure="true" sslProtocol="TLS"
 keystoreFile="/etc/tomcat8/keystore.jks" keystorePass="$CERTPW" clientAuth="false"
 ciphers="TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,
TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA,
TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA,
TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,
TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384,
TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,
TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,
TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256,
TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384,
TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256,
TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384" />
EOG
  cat splitted* > $TOMCAT_CONF_FILE
  rm -f $OLD_TOMCAT_CONF_FILE.tmp* splitted*


  TOMCAT_USER_FILE="/etc/tomcat8/tomcat-users.xml"
  OLD_TOMCAT_USER_FILE=$TOMCAT_USER_FILE.$(date +%Y%m%d-%H%M%S)
  cp $TOMCAT_USER_FILE $OLD_TOMCAT_USER_FILE
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
  Hi there you!
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
  apt-get -y purge tomcat8-admin && \
  apt-get -y purge tomcat8 && \
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
