#!/usr/bin/env bash

# change me
steamapps=$HOME/.local/share/Steam/steamapps

export WINEPREFIX=$HOME/.local/share/vrcx

set -e

# Ensure Wine version >= 9.0
wine_version=$(wine64 --version | grep -Po '(?<=wine-)([0-9.]+)')
if [ "$1" != "force" ] && [[ $wine_version < 9.0 ]]; then
	echo "Please upgrade your Wine version to 9.0 or higher."
	echo "If you want to try anyway, run: install-vrcx.sh force"
	exit 1
fi

if [[ ! -d $WINEPREFIX ]]; then
	echo "Creating Wine prefix."
	logs=$(winecfg /v win10 2>&1)
	if [ "$?" -ne "0" ]; then
		echo "*********** Error while creating Wine prefix ***********"
		echo "$logs"
		echo "*********** Error while creating Wine prefix ***********"
		exit 1
	fi
fi

if [[ ! -d $steamapps ]] && [[ -d $HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps ]]; then
	echo "Flatpak Steam detected."
	steamapps=$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps
fi

vrc_appdata=$steamapps/438100/pfx/drive_c/users/steamuser/AppData/LocalLow/VRChat/VRChat
vrc_dst=$WINEPREFIX/drive_c/users/$USER/AppData/LocalLow/VRChat/VRChat

if [[ -d $vrc_appdata ]]; then
	echo "No VRC installation detected."
	echo "If you want to use VRC on this computer, please install it now and start it once."
	echo "Otherwise, you will lose out on some features, like "
	read -p "Press enter to continue"
fi

if [[ -d $vrc_appdata ]] && [[ ! -d $vrc_dst ]]; then
	echo "Link VRChat AppData into Wine Prefix"
	mkdir -p $(dirname $vrc_dst)
	ln -s $vrc_appdata $vrc_dst
fi

echo "Download .NET 8"
cd /tmp
wget -q --show-progress https://download.visualstudio.microsoft.com/download/pr/93961dfb-d1e0-49c8-9230-abcba1ebab5a/811ed1eb63d7652325727720edda26a8/dotnet-sdk-8.0.100-win-x64.exe

echo "Install .NET 8"
logs=$(wine64 dotnet-sdk-8.0.100-win-x64.exe /quiet /norestart 2>&1)
if [ "$?" -ne "0" ]; then
	echo "*********** Error installing .NET 8 ***********"
	echo "$logs"
	echo "*********** Error installing .NET 8 ***********"
	exit 1
fi

rm dotnet-sdk-8.0.100-win-x64.exe

echo "Download VRCX"

if [[ ! -d $WINEPREFIX/drive_c/vrcx ]]; then
	mkdir -p $WINEPREFIX/drive_c/vrcx
fi

cd $WINEPREFIX/drive_c/vrcx
wget -q --show-progress https://github.com/galister/VRCX/releases/download/v2023.12.24-linux/vrcx.zip
unzip -uq vrcx.zip
rm vrcx.zip

echo '#!/usr/bin/env bash 
export WINEPREFIX=$HOME/.local/share/vrcx
wine64 $WINEPREFIX/drive_c/vrcx/VRCX.exe -no-cef-sandbox' >~/.local/share/vrcx/drive_c/vrcx/vrcx
chmod +x ~/.local/share/vrcx/drive_c/vrcx/vrcx

if [[ -d ~/.local/bin ]]; then
	echo "Install vrcx to ~/.local/bin"
	ln -s ~/.local/share/vrcx/drive_c/vrcx/vrcx ~/.local/bin/vrcx || true
fi

if [[ -d $HOME/.local/share/applications ]]; then
	if [[ ! -f $HOME/.local/share/icons/VRCX.png ]]; then
		echo "Install VRCX.png to ~/.local/share/icons"
		cd ~/.local/share/icons/
		wget -q --show-progress https://github.com/vrcx-team/VRCX/blob/v2023.12.24/VRCX.png
	fi

	echo "Install vrcx.desktop to ~/.local/share/applications"
	echo "[Desktop Entry]
Type=Application
Name=VRCX
Categories=Utility;
Exec=/home/$USER/.local/share/vrcx/drive_c/vrcx/vrcx
Icon=VRCX
" >~/.local/share/applications/vrcx.desktop
fi

echo "Done! Check your menu for VRCX."
