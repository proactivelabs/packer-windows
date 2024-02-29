REM Customise *this* file
REM Chocolatey will work here

REM Fetch QEMU Guest Agent
msiexec /qb /i "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-qemu-ga/qemu-ga-x86_64.msi"

REM Install chocolatey
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

REM Install spice-agent
choco install spice-agent -y

REM Create file indicating system is not yet sysprepped
REM This is deleted using the Firstboot-Autounattend file
copy C:\windows\system32\cmd.exe C:\not-yet-finished
