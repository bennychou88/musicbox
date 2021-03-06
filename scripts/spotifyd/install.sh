#!/bin/bash

## Install Spotifyd

# Import Helpers
DIR=`dirname $0`
pushd $DIR > /dev/null
. ../various/helpers.sh

# Check User
check_user_ability

echo -e "$INFO Installing and Configuring Spotifyd"
echo -n "Do you want to continue [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`

if [ "$answer" = "y" ]; then
  DLFILE=spotifyd-2019-02-25-armv6.zip
  DLHOST=https://github.com/Spotifyd/spotifyd/releases/download/v0.2.5

  echo -e "$INFO Downloading Spotifyd"
  mkdir -p ~/sw
  pushd ~/sw > /dev/null
  wget -q $DLHOST/$DLFILE
  if [ $? -eq 0 ]; then
    if [ -f $DLFILE ]; then
      echo -e "$INFO Extracting spotifyd to /usr/local/sbin"
      unzip $DLFILE
      if [ -x spotifyd ]; then
        sudo cp spotifyd /usr/local/sbin
        rm spotifyd
        popd > /dev/null

        echo -e "$INFO Installing Spotifyd service"
        sudo cp spotifyd.service /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable spotifyd.service

        echo -e "$INFO Configuring Spotifyd"
        sudo cp spotifyd.conf /etc/
        sudo chmod 600 /etc/spotifyd.conf

        # Read Spotify Config from mopidy
        if [ -f /etc/mopidy/mopidy.conf ]; then
          SPOT_CFG=`sudo sed '/^\[spotify\]/,/^\[.*\]/!d;//d' /etc/mopidy/mopidy.conf`
          username=`echo "$SPOT_CFG" | grep username | awk -F= '{print $2}' | tr -d ' '`
          password=`echo "$SPOT_CFG" | grep password | awk -F= '{print $2}' | tr -d ' '`
        fi

        # Check for dummy username / password
        if echo "$username" | grep -q "alice"; then
          if echo "$password" | grep -q "secret"; then
            usernamne=""
            password=""
          fi
        fi

        # If no exiting config for spotify - ask user
        if ! [ "$username" -a "$password" ]; then
          echo -n "      Spotify Username: "
          read username
          echo -n "      Spotify Password: "
          read password
        fi

        # Check if we can write the config
        if [ "$username" -a "$password" ]; then
          devicename=`hostname`
          sudo sed -i "s/^username =/username = $username/" /etc/spotifyd.conf
          sudo sed -i "s/^password =/password = $password/" /etc/spotifyd.conf
	  sudo sed -i "s/^device_name =/device_name = $devicename/" /etc/spotifyd.conf

          echo -e "$INFO Starting Spotifyd"
          sudo systemctl start spotifyd.service
        else
          echo -e "$WARNING: Empty username or password given."
          echo    "          Please configure manually in /etc/spotifyd.conf"
        fi
      else
        echo -e "$ERROR spotifyd could not be extracted"
        popd > /dev/null
      fi
    else
      echo -e "$ERROR $DLFILE not found"
      popd > /dev/null
    fi
  else
    echo -e "$ERROR Unable to download $DLHOST/$DLFILE"
    popd > /dev/null
  fi
fi
echo

popd > /dev/null
