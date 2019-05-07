#!/bin/sh

#This script is developed in accordance with the Synology Download Station Official API
#http://download.synology.com/download/Document/DeveloperGuide/Synology_Download_Station_Web_API.pdf

# MIT License
#
# Copyright (c) 2019 xaozai
# https://github.com/xaozai/ds-cli
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


DSADDR="https://127.0.0.1:4001"
DSUSER="admin"

RED='\033[0;31m'
GREEN='\033[0;32m'
GRAY='\033[0;37m'
DEFFONT='\033[0m'

display_usage() {
	echo -e "This script is designed to manage Synology Download Station tasks from the command line.\n"
	echo -e "\e[4mUsage:${DEFFONT} "
	printf "%-25s %s\n" "ds.sh a Task DPath" "add a new task"
	printf '\t%-22s \e[1m%s\e[m' " " "Task"
	printf "%s\n" " - URL | path | magnet"
	printf '\t%-22s \e[1m%s\e[m' " " "DPath"
	printf "%s\n" " - a path where the task will be downloaded (in the shared folder)"
	printf "%-25s %s\n" "ds.sh s id" "show tasks"
	printf "%-25s %s\n" "ds.sh p id" "pause tasks"
	printf "%-25s %s\n" "ds.sh r id" "resume tasks"
	printf "%-25s %s\n" "ds.sh d id" "delete tasks"
	printf '\t%-22s \e[1m%s\e[m' " " "id"
	printf "%s\n" " - task IDs to be deleted, separated by \",\""
	printf "%-25s %s\n" "ds.sh -h" "show this help"
	echo -e "\n\e[4mExamples:${DEFFONT}"
	echo -e "./ds.sh a \"magnet:?xt=urn:btih:5e1...d0c1fb&dn=t.org&tr=udp://t.org:2310&tr=udp://t.org:2310&tr=rt.loc/announce\" \"video/movie\""
	echo -e "./ds.sh a \"http://t.org/t/a.t.org/down/12345\" \"video/movie\""
	echo -e "./ds.sh a \"/volume1/homes/user/directory/file.torrent\" \"install/games\""
	echo -e "./ds.sh a \"/volume1/homes/user/directory/urls.txt\" \"some/stuff\""
	echo -e "./ds.sh s"
	echo -e "./ds.sh p dbid_1282"
	echo -e "./ds.sh d \"dbid_1282,dbid_1283\""
	echo -e "\n${GRAY}To start the DiskStation service (if it is stopped) from the command line you can use: sudo synopkg start DownloadStation${DEFFONT}"
}

checkHelp() {
	if [[ ($1 == "--help") || ($1 == "-h") ]]
	then
		display_usage
		exit 0
	fi
}

errDescr() {
	arr[0]="100 Unknown error"
	arr[1]="101 Invalid parameter"
	arr[2]="102 The requested API does not exist"
	arr[3]="103 The requested method does not exist"
	arr[4]="104 The requested version does not support the functionality"
	arr[5]="105 The logged in session does not have permission"
	arr[6]="106 Session timeout"
	arr[7]="107 Session interrupted by duplicate login"
	arr[8]="400 File upload failed"
	arr[9]="401 Max number of tasks reached"
	arr[10]="402 Destination denied"
	arr[11]="403 Destination does not exist"
	arr[12]="404 Invalid task id"
	arr[13]="405 Invalid task action"
	arr[14]="406 No default destination"
	arr[15]="407 Set destination failed"
	arr[16]="408 File does not exist"
	for i in "${arr[@]}"; do
		if [[ ${i:0:3} == "$1" ]]; then
			echo -e ${i:4} ${DEFFONT}
			break
		fi
	done
}

prepareStr() {
	echo -n $1 | sed -e "s/%/%25/g" | sed -e "s/+/%2B/g"  | sed -e "s/ /%20/g" | sed -e "s/&/%26/g"  | sed -e "s/=/%3D/g"
}

checkRes() {
    if [ "$(echo "$1" | jq -r '.success')" != "true" ]
	then
	    echo -e "\n${RED}Error: $(echo "$1" | jq -r '.error.code')"
        errDescr $(echo "$1" | jq -r '.error.code')
		exit 1
	else
		echo -e "${GREEN} OK${DEFFONT}"
	fi
}

checkAPI() {
	echo -en "Check API availability..."
	local RES=$(wget --no-check-certificate -qO - $DSADDR"/webapi/query.cgi?api=SYNO.API.Info&version=1&method=query&query=SYNO.API.Auth,SYNO.DownloadStation.Task")
	checkRes "$RES"
}

authenticate() {
	echo -en "Authenticating..."
	local RES=$(wget --no-check-certificate -qO - $DSADDR"/webapi/auth.cgi?api=SYNO.API.Auth&version=2&method=login&account=$DSUSER&passwd=$1&session=DownloadStation&format=sid")
	checkRes "$RES"
	SID=$(echo "$RES" | jq -r '.data.sid')
}

dslogout() {
    echo -n "Logging out..."
	wget -qO - "$SYNO/webapi/auth.cgi?api=SYNO.API.Auth&version=1&method=logout&session=DownloadStation" > /dev/null 2>&1
	echo -e "${GREEN} OK${DEFCOLOR}"
}

if [ $# -lt 1 ] 
then 
	display_usage
	exit 1
fi
checkHelp $1

init() {
	read -s -p "Please enter $DSUSER's password: " DSPASS
	echo ""
	checkAPI
	authenticate "$DSPASS"
}

if [[ $1 == "a" ]]
then
	init
	echo -en "Adding the task..."
	if [ ${3:0:1} == "/" ]
	then
		DST=${3:1}
	else
		DST=$3
	fi
	if echo "$2" | grep -q "magnet:?" || echo "$2" | grep -q "ftp://" || echo "$2" | grep -q "ftps://" || echo "$2" | grep -q "sftp://" || echo "$2" | grep -q "http://" || echo "$2" | grep -q "https://" || echo "$2" | grep -q "thunder://" || echo "$2" | grep -q "flashget://" || echo "$2" | grep -q "qqdl://"
	then
		RES=$(wget --no-check-certificate -qO - --post-data "api=SYNO.DownloadStation.Task&version=1&method=create&uri=$(prepareStr "$2")&destination=$DST&_sid=$SID" $DSADDR"/webapi/DownloadStation/task.cgi")
	else
		RES=$(curl -s -k -F"api=SYNO.DownloadStation.Task" -F "version=1" -F "method=create" -F "destination=$DST" -F "_sid=$SID" -F"file=@$2" $DSADDR"/webapi/DownloadStation/task.cgi")
	fi
elif [[ $1 == "p" ]]
then
	init
	echo -en "Pausing the task..."
	RES=$(wget --no-check-certificate -qO - --post-data "api=SYNO.DownloadStation.Task&version=1&method=pause&id=$2&_sid=$SID" $DSADDR"/webapi/DownloadStation/task.cgi")
elif [[ $1 == "r" ]]
then
	init
	echo -en "Resuming the task..."
	RES=$(wget --no-check-certificate -qO - --post-data "api=SYNO.DownloadStation.Task&version=1&method=resume&id=$2&_sid=$SID" $DSADDR"/webapi/DownloadStation/task.cgi")
elif [[ $1 == "d" ]]
then
	init
	echo -en "Deleting the tasks..."
	RES=$(wget --no-check-certificate -qO - --post-data "api=SYNO.DownloadStation.Task&version=1&method=delete&id=$2&_sid=$SID" $DSADDR"/webapi/DownloadStation/task.cgi")	
elif [[ $1 == "s" ]]
then
	init
	echo -en "Getting tasks..."
	RES=$(wget --no-check-certificate -qO - --post-data "api=SYNO.DownloadStation.Task&version=1&method=list&_sid=$SID" $DSADDR"/webapi/DownloadStation/task.cgi")
	checkRes "$RES"
	echo ""
	printf "%-11s | %-12s | %s\n" "id" "status" "title"
	printf "%-11s | %-12s | %s\n" "-----------" "------------" "-------------------------------"
	for row in $(echo "${RES}" | jq -r '.data.tasks[] | @base64'); do
	    _jq() {
	        echo ${row} | base64 --decode | jq -r ${1}
	    }
	    printf "%-11s | %-12s | %s\n" "$(_jq '.id')" "$(_jq '.status')" "$(_jq '.title')"
	done
	echo ""
else
	display_usage
	exit 1
fi

if [[ $1 != "s" ]]
then
	checkRes "$RES"
fi

dslogout

