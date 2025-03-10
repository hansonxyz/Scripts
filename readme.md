# HansonXYZ Scripts

This repository is a collection of the most useful scripts that are used on a day-to-day basis. 

## Descriptions 

[**db.sh**](https://github.com/hansonxyz/Scripts/blob/main/db.sh): A handy tool designed for Laravel and WordPress projects that simplifies the interaction with MySQL databases directly from the shell.

[**encrypt_to_shellscript.sh**](https://github.com/hansonxyz/Scripts/blob/main/encrypt_to_shellscript.sh): This script generates an encrypted tar.gz file and a companion shell script. When executed, the shell script prompts the user for a password, which is required to extract the contents of the encrypted tar.gz file.

[**java_project_renamer.py**](https://github.com/hansonxyz/Scripts/blob/main/java_project_renamer.py): This script finds and replaces a namespace with another namespace in a project, and updates the directory structure to match.

[**tmux_remote_persistent.sh**](https://github.com/hansonxyz/Scripts/blob/main/tmux_remote_persistent.sh): This script enables connection to a remote Linux system and initializes a tmux session. It provides resilience by automatically reconnecting to the tmux session in case the terminal is unexpectedly disconnected.

[**multi_terminal.ps1**](https://github.com/hansonxyz/Scripts/blob/main/multi_terminal.ps1): A powershell script that starts windows terminal and creates multiple persistent terminals using wsl + [**tmux_remote_persistent.sh**](https://github.com/hansonxyz/Scripts/blob/main/tmux_remote_persistent.sh)

[**report_active_state_windows_workstation.ps1**](https://github.com/hansonxyz/Scripts/blob/main/report_active_state_windows_workstation.ps1): A powershell script that pulls a web endpoint via web request every 30 seconds while the workstation is in use.  For use with something like home assistant.

[**wgett.sh**](https://github.com/hansonxyz/Scripts/blob/main/wgett.sh): A bash script which downloads a torrent file to the local directory and exits, in the same manner wget works.

[**yt-dl.py**](https://github.com/hansonxyz/Scripts/blob/main/yt-dl.py): A python script which invokes docker and pulls the latest version of youtube-dl to download a target youtube video.  Pass argument --mp3 or --x265 to have it convert to either a mp3 or x265 formatted file via ffmpeg via docker.  Requires no dependencies other than python3 and the ability to execute docker via sudo.

## License

The scripts in this project are licensed under the terms of the MIT license.

