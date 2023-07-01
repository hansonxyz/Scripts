$commands = @(
    "cd /root; sudo bash",
    "bash",
    "pwsh",
)

$wsl_distro = "Ubuntu-22.04"

$remote_server =user@server.ip.or.host" 

$wtCommand = "$env:LocalAppData\Microsoft\WindowsApps\wt.exe"

$counter = 1
$tabs = foreach ($command in $commands) {
    $sessionName = "lpsession_$counter"
    $counter++

    $escapedCommand = $command -replace "'", "''"
    $escapedCommand = $escapedCommand -replace ";", "`\;"
    $tabCommand = "new-tab C:\WINDOWS\system32\wsl.exe -d $wsl_distro ./tmux_remote_persistent.sh $remote_server '$escapedCommand' $sessionName"
    $tabCommand
}

$wtCommand += " " + ($tabs -join " ``; ")
Invoke-Expression  $wtCommand
