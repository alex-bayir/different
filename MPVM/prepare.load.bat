@echo off
set userhost=%1
pscp .\prepare.sh %userhost%:/home/user && ssh %userhost% "chmod +x prepare.sh && sudo -S ./prepare.sh && rm prepare.sh"
@echo on