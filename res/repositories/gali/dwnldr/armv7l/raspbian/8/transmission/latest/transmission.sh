#!/usr/bin/env bash
################################################################################
#  Author: <a href="mailto:debuti@gmail.com">Borja Garcia</a>
# Program: transmission raspbian
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
  if ! $(which transmission-daemon > /dev/null); then
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
  apt-get -y install transmission-common && \
  apt-get -y install transmission-daemon && \
  apt-get -y install transmission-cli && \
  apt-get -y install transmission-remote-gtk && \
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
  echo -n "" > "$CONFIG_TEMP" && \
  echo -n 'Transmission user: ' && read us
  echo -n 'Transmission password: ' && read password 
  echo $us:$password >> "$CONFIG_TEMP" && echo ""
  result=0;  
  return $result;
}

# Configure this software
configure() {
  result=0;  
  US=$(cat "$CONFIG_TEMP"| cut -f1 -d":")
  PW=$(cat "$CONFIG_TEMP"| cut -f2 -d":")
  if [[ -z $PW ]]; then
    echo "Use preinstall first";
    return -1;
  fi;

  systemctl stop transmission-daemon

  # Config files
  TRANSMISSION_CONFIG_FILE="/etc/transmission-daemon/settings.json"
  OLD_TRANSMISSION_CONFIG_FILE=$TRANSMISSION_CONFIG_FILE.$(date +%Y%m%d-%H%M%S)
  TRANSMISSION_INIT_FILE="/etc/init.d/transmission-daemon"
  OLD_TRANSMISSION_INIT_FILE=$TRANSMISSION_INIT_FILE.$(date +%Y%m%d-%H%M%S)
  TRANSMISSION_SYSTEMD_FILE="/lib/systemd/system/transmission-daemon.service"
  OLD_TRANSMISSION_SYSTEMD_FILE=$TRANSMISSION_SYSTEMD_FILE.$(date +%Y%m%d-%H%M%S)

  # First time it substitutes the pwd by itself
  mv $TRANSMISSION_CONFIG_FILE $OLD_TRANSMISSION_CONFIG_FILE
  cat $OLD_TRANSMISSION_CONFIG_FILE |
  sed 's/alt-speed-up".*/alt-speed-up": 50, /g' |
  sed 's/alt-speed-down".*/alt-speed-down": 50, /g' |
  sed 's/alt-speed-enabled".*/alt-speed-enabled": true,/g' |
  sed 's/alt-speed-time-begin".*/alt-speed-time-begin": 540, /g' |
  sed 's/alt-speed-time-day".*/alt-speed-time-day": 127, /g' |
  sed 's/alt-speed-time-enabled".*/alt-speed-time-enabled": true, /g' |
  sed 's/alt-speed-time-end".*/alt-speed-time-end": 1425, /g' |
  sed 's/download-dir".*/download-dir": "\/media\/hd_media\/Downloads\/Incoming\/files", /g' |
  sed 's/filter-mode".*/filter-mode": "show-all", /g' |
  sed 's/inhibit-desktop-hibernation".*/inhibit-desktop-hibernation": true, /g' |
  sed 's/main-window-height".*/main-window-height": 500, /g' |
  sed 's/main-window-is-maximized".*/main-window-is-maximized": 0, /g' |
  sed 's/main-window-layout-order".*/main-window-layout-order": "menu,toolbar,filter,list,statusbar", /g' |
  sed 's/main-window-width".*/main-window-width": 467, /g' |
  sed 's/peer-port".*/peer-port": 4662, /g' |
  sed 's/peer-port-random-on-start".*/peer-port-random-on-start": false, /g' |
  sed 's/prompt-before-exit".*/prompt-before-exit": true, /g' |
  sed 's/queue-stalled-minutes".*/queue-stalled-minutes": 1440, /g' |
  sed 's/queue-stalled-enabled".*/queue-stalled-enabled": true, /g' |
  sed 's/ratio-limit".*/ratio-limit": 2, /g' |
  sed 's/ratio-limit-enabled".*/ratio-limit-enabled": true, /g' |
  sed 's/show-desktop-notification".*/show-desktop-notification": true, /g' |
  sed 's/show-filterbar".*/show-filterbar": true, /g' |
  sed 's/show-notification-area-icon".*/show-notification-area-icon": true, /g' |
  sed 's/show-options-window".*/show-options-window": false, /g' |
  sed 's/show-statusbar".*/show-statusbar": true, /g' |
  sed 's/show-toolbar".*/show-toolbar": true, /g' |
  sed 's/sort-mode".*/sort-mode": "sort-by-progress", /g' |
  sed 's/sort-reversed".*/sort-reversed": false, /g' |
  sed 's/speed-limit-down".*/speed-limit-down": 250, /g' |
  sed 's/speed-limit-down-enabled".*/speed-limit-down-enabled": true, /g' |
  sed 's/speed-limit-up".*/speed-limit-up": 250, /g' |
  sed 's/speed-limit-up-enabled".*/speed-limit-up-enabled": true, /g' |
  sed 's/start-added-torrents".*/start-added-torrents": true, /g' |
  sed 's/statusbar-stats".*/statusbar-stats": "total-ratio", /g' |
  sed 's/trash-original-torrent-files".*/trash-original-torrent-files": true, /g' |
  sed 's/user-has-given-informed-consent".*/user-has-given-informed-consent": true, /g' |
  sed 's/watch-dir".*/watch-dir": "\/media\/hd_media\/Queues\/nettop\/Torrents", /g' |
  sed 's/watch-dir-enabled".*/watch-dir-enabled": true/g'|
  sed 's/incomplete-dir".*/incomplete-dir": "\/media\/hd_media\/Downloads\/Temp", /g'|
  sed 's/incomplete-dir-enabled".*/incomplete-dir-enabled": true, /g'|
  sed 's/script-torrent-done-enabled".*/script-torrent-done-enabled": false, /g'|
  sed 's/script-torrent-done-filename".*/script-torrent-done-filename": "", /g'|
  sed 's/pex-enabled".*/pex-enabled": true, /g'|
  sed 's/dht-enabled".*/dht-enabled": true, /g'|
  sed 's/lpd-enabled".*/lpd-enabled": true, /g'|
  sed 's/rpc-whitelist-enabled".*/rpc-whitelist-enabled": false, /g' |
  sed 's/rpc-authentication-required".*/rpc-authentication-required": true, /g' |
  sed "s/rpc-username\".*/rpc-username\": \"$US\", /g" |
  sed "s/rpc-password\".*/rpc-password\": \"$PW\", /g"|
  sed 's/rpc-port".*/rpc-port": 9091, /g'|
  sed 's/rpc-enabled".*/rpc-enabled": true, /g' > $TRANSMISSION_CONFIG_FILE
  chmod 755 $TRANSMISSION_CONFIG_FILE
  chown debian-transmission:debian-transmission $TRANSMISSION_CONFIG_FILE
    
  mv $TRANSMISSION_INIT_FILE $OLD_TRANSMISSION_INIT_FILE
  cat $OLD_TRANSMISSION_INIT_FILE | grep -v "chuid"> $TRANSMISSION_INIT_FILE
  chmod 755 $TRANSMISSION_INIT_FILE

  mv $TRANSMISSION_SYSTEMD_FILE $OLD_TRANSMISSION_SYSTEMD_FILE
  cat $OLD_TRANSMISSION_SYSTEMD_FILE |
  sed "s/^ExecStart=.*/ExecStart=\/usr\/bin\/transmission-daemon -g \/var\/lib\/transmission-daemon\/.config\/transmission-daemon -f/g"|
  sed "s/^User=.*/User=$US/g"|
  sed "s/^After=.*/After=multi-user.target/g" > $TRANSMISSION_SYSTEMD_FILE
  systemctl daemon-reload
  chown -R $US:$US /var/lib/transmission-daemon /etc/transmission-daemon

  systemctl start transmission-daemon

  # transmission-remote-gtk configuration
  mkdir -p /home/$US/.config/transmission-remote-gtk
  cat > /home/$US/.config/transmission-remote-gtk/config.json << EOG
{
  "profiles" : [
    {
      "profile-name" : "Default",
      "hostname" : "localhost",
      "port" : 9091,
      "rpc-url-path" : "/transmission/rpc",
      "username" : "$US",
      "password" : "$PW",
      "auto-connect" : true,
      "ssl" : false,
      "timeout" : 40,
      "retries" : 3,
      "update-active-only" : false,
      "activeonly-fullsync-enabled" : false,
      "activeonly-fullsync-every" : 2,
      "update-interval" : 3,
      "min-update-interval" : 3,
      "session-update-interval" : 60,
      "exec-commands" : [
      ],
      "destinations" : [
      ]
    }
  ],
  "profile-id" : 0,
  "tree-views" : {
    "TrgTorrentTreeView" : {
    },
    "TrgTrackersTreeView" : {
    },
    "TrgFilesTreeView" : {
    },
    "TrgPeersTreeView" : {
    }
  },
  "start-paused" : false,
  "add-options-dialog" : true,
  "delete-local-torrent" : false,
  "show-state-selector" : true,
  "filter-dirs" : true,
  "filter-trackers" : true,
  "show-notebook" : false,
  "system-tray" : false,
  "system-tray-minimise" : false,
  "add-notify" : false,
  "complete-notify" : false
}
EOG
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
  result=0;  
  mv  /etc/transmission-daemon/settings.json /etc/transmission-daemon/settings.json.old
  apt-get -y purge transmission-common transmission-daemon transmission-cli transmission-remote-gtk && \
  apt-get -y clean && \
  apt-get -y autoremove && \
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
