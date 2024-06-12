#!/usr/bin/env python3
import os
import subprocess
import datetime
import sys
import time

already_exists = False

def check_last_execution():
    last_execution_file = "/tmp/update-yt-dl.txt"
    current_date = datetime.datetime.now().strftime("%Y-%m-%d")
    if os.path.exists(last_execution_file):
        with open(last_execution_file, "r") as file:
            last_execution_date = file.read().strip()
    else:
        last_execution_date = ""

    if current_date != last_execution_date:
        print("Updating yt-dl docker container")
        subprocess.run(["docker", "pull", "mikenye/youtube-dl"])
        with open(last_execution_file, "w") as file:
            file.write(current_date)

def run_youtube_dl(yt_args):
    global already_exists
    has_printed_100 = False
    print("Downloading...")
    command = [
        "sudo", "docker", "run", "--rm", "-i",
        "--device", "/dev/dri:/dev/dri",
        "-e", f"PGID={os.getgid()}",
        "-e", f"PUID={os.getuid()}",
        "-v", f"{os.getcwd()}:/workdir:rw",
        "mikenye/youtube-dl", "--no-check-certificate"
    ] + yt_args

    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    download_path = None
    last_eta_time = None
    for line in process.stdout:
        if "[download] Destination:" in line:
            download_path = line.split(": ")[-1].strip()
            print("Download identified as " + download_path)
        if "[download]" in line and "already been downloaded" in line:
            download_path = line.split(" has")[0].split("[download] ")[-1].strip()
            print("Download already exists: " + download_path)
            already_exists = True

        if "[download]" in line and "100%" in line and not has_printed_100:
            print(line.strip())
            has_printed_100 = True
        elif "[download]" in line and "ETA" in line:
            if not last_eta_time or time.time() - last_eta_time > 5:
                last_eta_time = time.time()
                print(line.strip())

        if not any([x in line for x in ["Destination:", "already been downloaded", "ETA", "100%"]]):
            print(line, end='')

    if download_path and not os.path.exists(download_path):
        parts = download_path.split('.')
        if len(parts) > 2:
            adjusted_path = '.'.join(parts[:-2] + [parts[-1]])  # Remove the second to last piece
            if os.path.exists(adjusted_path):
                download_path = adjusted_path
                print("Adjusted download path to existing file: " + download_path)
            else:
                print("No valid download file found.")
        else:
            print("No adjustments possible for download path.")

    return download_path

def convert_media(download_path, convert_type):
    global already_exists
    if download_path and os.path.exists(download_path):
        base_name = os.path.splitext(download_path)[0]
        output_path = f"{base_name}.{'mp3' if convert_type == '--mp3' else 'mp4'}"
        conversion_command = [
            "sudo", "docker", "run", "--rm",
            "-v", f"{os.getcwd()}:/workdir:rw",
            "jrottenberg/ffmpeg", "-i", f"/workdir/{download_path}", "-hide_banner"
        ]

        if convert_type == "--mp3":
            conversion_command += ["-b:a", "256k", f"/workdir/{output_path}"]
        elif convert_type == "--h265":
            conversion_command += ["-c:v", "libx265", "-b:v", "4M", "-c:a", "aac", "-b:a", "192k", f"/workdir/{output_path}"]

        subprocess.run(conversion_command)

        if os.path.exists(output_path):
            os.chmod(output_path, 0o666)
            print(f"{output_path} successfully converted")
            if not already_exists:
                os.remove(download_path)
        else:
            print(f"Conversion failed for {download_path}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: yt-dl [--mp3 | --h265] [--playlist] [youtube-dl arguments]")
        sys.exit(1)

    yt_dl_flags = [arg for arg in sys.argv[1:] if arg not in ['--mp3', '--h265', '--playlist']]
    conversion_type = '--mp3' if '--mp3' in sys.argv else '--h265' if '--h265' in sys.argv else None
    playlist_mode = '--playlist' in sys.argv

    if not playlist_mode:
        yt_dl_flags.append('--no-playlist')

    check_last_execution()
    download_path = run_youtube_dl(yt_dl_flags)

    if conversion_type and not playlist_mode:
        convert_media(download_path, conversion_type)
