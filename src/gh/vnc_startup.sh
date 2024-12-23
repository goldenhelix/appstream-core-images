#!/bin/bash
### every exit != 0 fails the script
set -e

# should also source $STARTUPDIR/generate_container_user
source $HOME/.bashrc

# Set lang values
if [ "${LC_ALL}" != "en_US.UTF-8" ]; then
  export LANG=${LC_ALL}
  export LANGUAGE=${LC_ALL}
fi

# Dbus
export $(dbus-launch)

## correct forwarding of shutdown signal
cleanup () {
    kill -s SIGTERM $!
    exit 0
}
trap cleanup SIGINT SIGTERM

add_vnc_user() {
  local username="$1"
  local password="$2"
  local permission_option="$3"

  echo "Adding user $username"
  echo -e "$password\n$password" | kasmvncpasswd $permission_option \
    -u "$username" $HOME/.kasmpasswd
}

## resolve_vnc_connection
VNC_IP=$(hostname -i)

# first entry is control, second is view (if only one is valid for both)
mkdir -p "$HOME/.vnc"
add_vnc_user "$VNC_USER" "$VNC_PW" "-wo"
#add_vnc_user "$VNC_USER-ro" "$VNC_PW"
unset VNC_PW # don't need it anymore
chmod 0600 $HOME/.kasmpasswd

# if IDLE_TIMEOUT env variable is set, write a user config file (read after the system /etc/kasmvnc.yaml)
if [ -n "$IDLE_TIMEOUT" ]; then
  cat <<EOF > $HOME/.vnc/kasmvnc.yaml
server:
  auto_shutdown:
    no_user_session_timeout: $IDLE_TIMEOUT
    inactive_user_session_timeout: $IDLE_TIMEOUT
EOF
fi

# Try to create a username based directory, only update .config/user-dirs.dirs if it succeeds
set +e
mkdir -p $HOME/Workspace/Documents/$USERNAME
if [ -d $HOME/Workspace/Documents/$USERNAME ]; then
  cat <<EOF > $HOME/.config/user-dirs.dirs
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_DOCUMENTS_DIR="$HOME/Workspace/Documents/$USERNAME"
EOF
  BOOKMARKS_FILE="$HOME/.config/gtk-3.0/bookmarks"
  mkdir -p "$(dirname "$BOOKMARKS_FILE")"
  : > "$BOOKMARKS_FILE"
  for folder in "$HOME/Workspace"/*/; do
    [ -d "$folder" ] || continue
    # Add the directory to the bookmarks file in the required format
    escaped_folder=$(echo "$folder" | sed 's/ /%20/g')
    echo "file://$escaped_folder" >> "$BOOKMARKS_FILE"
  done
fi
set -e

# Generate SSL certificate
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout $HOME/.vnc/self.pem -out $HOME/.vnc/self.pem -subj "/C=US/ST=VA/L=None/O=None/OU=DoFu/CN=kasm/emailAddress=none@none.none" &> $HOME/.vnc/vnc_startup.log

if [[ $DEBUG == true ]]; then
  echo "remove old vnc locks to be a reattachable container"
fi
vncserver -kill $DISPLAY &> $HOME/.vnc/vnc_startup.log \
    || rm -rfv /tmp/.X*-lock /tmp/.X11-unix &> $HOME/.vnc/vnc_startup.log \
    || echo "no locks present"


[ -n "$KASMVNC_VERBOSE_LOGGING" ] && verbose_logging_option="-debug"

vncserver $DISPLAY -select-de manual -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION -FrameRate=$MAX_FRAME_RATE -websocketPort $NO_VNC_PORT -sslOnly -interface 0.0.0.0 -BlacklistThreshold=0 -FreeKeyMappings $VNCOPTIONS $verbose_logging_option &> $STARTUPDIR/no_vnc_startup.log

echo "Starting window manager XFCE..."
DISPLAY=:1 /usr/bin/startxfce4 --replace &
PID_SUB=$!

### disable screen saver and power management
xset -dpms &
xset s noblank &
xset s off &
# xset q # debug xset settings

## log connect options
echo -e "\n\n------------------ VNC environment started ------------------"
echo -e "\nConnect via https://$VNC_IP:$NO_VNC_PORT/\n"
echo "WEB PID: $PID_SUB"

# tail vncserver logs
tail -f $HOME/.vnc/*$DISPLAY.log &

# Specialized containers that use this as a base image can add a custom startup script
custom_startup_script=/dockerstartup/custom_startup.sh
if [ -f "$custom_startup_script" ]; then
  if [ ! -x "$custom_startup_script" ]; then
    echo "${custom_startup_script}: not executable, exiting"
    exit 1
  fi

  "$custom_startup_script" &
  echo "Executed custom startup script."
fi

# We shut down the container when the XFCE4 window manager exits
wait $PID_SUB

echo "Exiting VNC container"
