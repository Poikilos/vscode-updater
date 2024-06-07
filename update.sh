#!/usr/bin/env bash

OS=$(lsb_release -si);
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
DIST="";
ARCH=$(uname -m);

if [ -f /etc/os-release ]; then
    source /etc/os-release
    # ^ If not ubuntu but is Ubuntu-based, may contain:
    # UBUNTU_CODENAME=jammy
    # ^ (if set at all, it is Ubuntu-based). However, the more standard variable is:
    # ID_LIKE="ubuntu debian"
    for name in $ID_LIKE; do
        if [ "$name" = "ubuntu" ]; then
            DIST="deb";
        elif [ "$name" = "debian" ]; then
            DIST="deb";
        fi
    done
fi

if [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian" ]; then
    DIST="deb";
elif [ "$OS" = "Fedora" ] || [ "$OS" = "Red Hat" ] || [ "$OS" = "Red hat" ]; then
    DIST="rpm";
elif [ -z "$DIST" ]; then
    echo "Unfortunately your operating system is not supported in distributed packages.";
    exit;
fi

if [ "$ARCH" = "x86_64" ]; then
    ARCH="x64";
elif [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64";
else
    echo "Unfortunately your architecture is not supported in distributed packages.";
    exit;
fi

URLBASE="https://code.visualstudio.com/sha/download?build=stable&os=linux-${DIST}-${ARCH}";
FILENAME="$DIR/latest.${DIST}";

if test -e "$FILENAME"; then
    rm $FILENAME;
    echo "Removed last downloaded version.";
fi

echo "Downloading latest version of vscode is starting...";
wget --show-progress -O $FILENAME $URLBASE;
RESULT="$?";
if ((RESULT != 0)); then
    echo "Failed to download.";
    exit 1;
fi
printf "Downloading finished.\n\n";

echo "Closing vscode...";
for pid in $(pidof code); do kill -9 $pid; done
echo "vscode instance(s) closed.";

echo "Installing latest version...";
if [ "$DIST" = "deb" ]; then
    sudo dpkg -i $FILENAME;
    sudo apt-get update
    sudo apt-get install -f -y  # -f: install dependencies
else
    # sudo rpm -i $FILENAME;
    yum --nogpgcheck localinstall $FILENAME;  # Install and get dependencies
fi
echo "Installation finished.";

echo "Starting new version of vscode...";
code &
exit;
