## ds-cli
**ds-cli** is a bash script for managing Synology DownloadStation tasks from the command line.  
This script is developed in accordance with the [Synology Download Station Official API](http://download.synology.com/download/Document/DeveloperGuide/Synology_Download_Station_Web_API.pdf "Synology Download Station Official API")

#### Installing
You can use these commands:
```
git clone https://github.com/xaozai/ds-cli.git
cd ds-cli
chmod +x ds.sh
```
Or you can manually download the script and set the executable attribute.  
Then you have to set two values in the file ds.sh: *DSADDR* and *DSUSER*.  
*DSADDR* is the address of your device on the network; *DSUSER* is the user name for logging in to the system.  
I do not recommend to change other parameters in this file.


#### Usage
```
ds.sh a Task DPath		add a new task
							Task - URL | path | magnet
							DPath - a path where the task will be downloaded (in the shared folder)
ds.sh s					show tasks
ds.sh p id				pause tasks
ds.sh r id				resume tasks
ds.sh d id				delete tasks
							id - task IDs to be deleted, separated by ","
```

Examples:
```
./ds.sh a "magnet:?xt=urn:btih:5e1...d0c1fb&dn=t.org&tr=udp://t.org:2310&tr=udp://t.org:2310&tr=rt.loc/announce" "video/movie"
./ds.sh a "http://t.org/t/a.t.org/down/12345" "video/movie"
./ds.sh a "/volume1/homes/user/directory/file.torrent" "install/games"
./ds.sh a "/volume1/homes/user/directory/urls.txt" "some/stuff"
./ds.sh s
./ds.sh p dbid_1282
./ds.sh d "dbid_1282,dbid_1283"
```

*To start the DiskStation service (if it is stopped) from the command line you can use: sudo synopkg start DownloadStation*
