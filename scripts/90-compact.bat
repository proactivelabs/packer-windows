REM Final cleanup before pushing out

REM Stop windows updates, remove cache
net stop wuauserv
rmdir /S /Q C:\Windows\SoftwareDistribution\Download
mkdir C:\Windows\SoftwareDistribution\Download

REM Shrink winsxs folder
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

REM Install sdelete in prep for zeroing unused space
choco install sdelete -y

REM zerofill disk for easy shrinking and compression
sdelete.exe /accepteula -z c:

REM compaction finished
REM The box will now be sysprepped and will be ready to go shortly

REM Directory listing of C:/
REM You want to make sure C:\not-yet-finished is in output here
dir C:\
