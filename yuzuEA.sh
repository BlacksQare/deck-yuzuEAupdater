#!/bin/bash
yuzuHost="https://api.github.com/repos/pineappleEA/pineapple-src/releases/latest"
metaData=$(curl -fSs ${yuzuHost})
fileToDownload=$(echo ${metaData} | jq -r '.assets[] | select(.name|test(".*.AppImage$")).browser_download_url')
currentVer=$(echo ${metaData} | jq -r '.tag_name')
home=$(getent passwd $USER | cut -d: -f6)
output=$home"/Applications/yuzu.AppImage"
showProgress="true"

createDesktop() {
	cat > yuzu.desktop.temp << EOF
[Desktop Entry]
Name=Yuzu EA
Exec=$home/Applications/yuzu.AppImage
Icon=$home/.local/share/applications/yuzu_ea.png
Comment=Nintendo Switch Emulator
Type=Application
Terminal=false
Encoding=UTF-8
Categories=Game;
StartupNotify=true
StartupWMClass=yuzu
EOF

	cat > yuzuEAUpdate.desktop.temp << EOF
[Desktop Entry]
Name=Update Yuzu EA
Exec=bash $home/Applications/yuzuEA.sh
Icon=$home/.local/share/applications/yuzu_ea.png
Comment=Nintendo Switch Emulator
Type=Application
Terminal=false
Encoding=UTF-8
Categories=Utility;
StartupNotify=true
StartupWMClass=yuzu
EOF

	mv -v yuzu.desktop.temp $home/.local/share/applications/yuzu.desktop
	chmod +x $home/.local/share/applications/yuzu.desktop

    mv -v yuzuEAUpdate.desktop.temp $home/.local/share/applications/yuzuEAUpdate.desktop
	chmod +x $home/.local/share/applications/yuzuEAUpdate.desktop

    curl -LJo "$home/.local/share/applications/yuzu_ea.png" "https://raw.githubusercontent.com/yuzu-emu/yuzu-assets/master/icons/icon_ea.png"
	curl -LJo "$home/Applications/yuzuEA.sh" "https://raw.githubusercontent.com/BlacksQare/deck-yuzuEAupdater/master/yuzuEA.sh"

	chmod +x $home/Applications/yuzuEA.sh
}

safeDownload() {
	local name="$1"
	local url="$2"
	local outFile="$3"
	local showProgress="$4"
	local headers="$5"

	echo "safeDownload()"
	echo "- $name"
	echo "- $url"
	echo "- $outFile"
	echo "- $showProgress"
	echo "- $headers"

	if [ "$showProgress" == "true" ] || [[ $showProgress -eq 1 ]]; then
		request=$(curl -w $'\1'"%{response_code}" --fail -L "$url" -H "$headers" -o "$outFile.temp" 2>&1 | tee >(stdbuf -oL tr '\r' '\n' | sed -u 's/^ *\([0-9][0-9]*\).*\( [0-9].*$\)/\1\n#Download Speed\:\2/' | zenity --progress --title "Downloading $name" --width 600 --auto-close --no-cancel 2>/dev/null) && echo $'\2'${PIPESTATUS[0]})
	else
		request=$(curl -w $'\1'"%{response_code}" --fail -L "$url" -H "$headers" -o "$outFile.temp" 2>&1 && echo $'\2'0 || echo $'\2'$?)
	fi
	requestInfo=$(sed -z s/.$// <<< "${request%$'\1'*}")
	returnCodes="${request#*$'\1'}"
	httpCode="${returnCodes%$'\2'*}"
	exitCode="${returnCodes#*$'\2'}"
	echo "$requestInfo"
	echo "HTTP response code: $httpCode"
	echo "CURL exit code: $exitCode"
	if [ "$httpCode" = "200" ] && [ "$exitCode" == "0" ]; then
		echo "$name downloaded successfully";
		mv -v "$outFile.temp" "$outFile"
		return 0
	else
		echo "$name download failed"
		rm -f "$outFile.temp"
		return 1
	fi
}


if [ "$showProgress" == "true" ] || [[ $showProgress -eq 1 ]]; then
	zenity --question --title="Yuzu EA Download" --width 200 --text "Yuzu ${currentVer} available. Would you like to download?" --ok-label="Yes" --cancel-label="No" 2>/dev/null
	if [ $? = 0 ]; then
		echo "download ${currentVer} appimage: ${fileToDownload}"
		if safeDownload "yuzu" "${fileToDownload}" "$output" "$showProgress"; then
			chmod +x "$output"
			createDesktop
		else
			zenity --error --text "Error downloading yuzu!" --width=250 2>/dev/null
			createDesktop
		fi
	fi
else 
	echo "download ${currentVer} appimage: ${fileToDownload}"
	if safeDownload "yuzu" "${fileToDownload}" "$output" "$showProgress"; then
		chmod +x "$output"
	fi
fi
