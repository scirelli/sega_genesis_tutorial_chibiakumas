@echo --------------------------------------------------------------------------
@echo 	Keith's Z80 Dev Toolkit - Please see the Readme for instructions!
@echo --------------------------------------------------------------------------
@echo 				Z Drive Mount tool V1.0
@echo. 			
@echo 		This tool mounts the 68000 tools to virtual drive X
@echo 	If the X drive is in use, W or V will be used as an alternative
@echo. 
@echo --------------------------------------------------------------------------
@echo off

set driveletter=X
if exist %driveletter%:\Xdrive.bat goto showmsg
if not exist %driveletter%:\nul goto start

set driveletter=W
if exist %driveletter%:\Sdrive.bat goto showmsg
if not exist %driveletter%:\nul goto start

set driveletter=V
if exist %driveletter%:\Sdrive.bat goto showmsg
if not exist %driveletter%:\nul goto start

Echo Drives X, W and V are in use already - could not map drive
pause
goto end

:start
subst %driveletter%: .
:showmsg

echo Development tools have been mounted as virtual drive %driveletter%:
pause
start %driveletter%:\
:end