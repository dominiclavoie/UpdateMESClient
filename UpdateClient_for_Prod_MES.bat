
REM ###################################################################
REM # program: UpdateClient_for_Prod.bat
REM #
REM # update client folder with missing files and Clear EpicorAlternateCache folder on local client 
REM # Created By: CRTI-GP - Concerti
REM #
REM # Last Revision Date: 2019-09-06 CRTI-GP
REM #
REM ###################################################################
@echo off
cls
SET envName=Prod
SET ProcessNameToKill="Epicor.exe"
SET FullPathLog=C:\EpicorClient\Scripts\Logs\UpdateClient_for_%envName%.log
SET xcopySourceFullPath=\\SERV-EPICOR01\EpicorClient\ERP10%envName%
SET xcopyTargetFullPath=C:\EpicorClient\ERP10%envName%
SET EpicorAlternateCache=C:\EpicorClient\AltCacheFolder\%envName%
SET configSourceFullPath=\\SERV-EPICOR01\EpicorData\%envName%\Config

setlocal EnableDelayedExpansion
SET userID=
SET password=
SET workstation=
SET custo=

(for /F "delims=" %%a in (%xcopyTargetFullPath%\config\user.txt) do (
   SET "line=%%a"
   if "!line:~0,7!"=="UserID|" (
      SET "userID="
	  for /f "tokens=2 delims=|" %%b in ("!line!") do (
	    SET "userID=%%b"
	  )
   ) else if "!line:~0,9!"=="Password|" (
      SET "password="
	  for /f "tokens=2 delims=|" %%b in ("!line!") do (
	    SET "password=%%b"
	  )
   )
))

SET uID=!userID!
SET pass=!password!
if not "%uID%"=="" (
  (for /F "delims=" %%a in (%configSourceFullPath%\userconfig.txt) do (
     SET "line=%%a"
     if not "x!line:%uID%=!"=="x!line!" (
        SET "userID="
	    for /f "tokens=2,3 delims=|" %%b in ("!line!") do (
	      SET "workstation=%%b"
	  	  SET "custo=%%c"
	    )
     )
  ))
)
SET ws=!workstation!
SET cus=!custo!

REM option that will only replace new files based on date : /S/R/C/F/D/Y
REM option that will FORCE replacement of all files       : /S/R/C/F/Y
SET xcopyCmdOption=/S/R/C/i/F/D/Y


REM ECHO.
REM ECHO.
REM ECHO ***********************************
REM ECHO.                                                              
REM ECHO Kill all %ProcessNameToKill% processes and deploy new client DLL 
REM ECHO NEED TO RUN AS ADMINISTRATOR                                     
REM ECHO ***********************************
REM ECHO.
REM ECHO.

ECHO ****START %date% %time% %username%****				 							>> %FullPathLog%
ECHO deploy new client DLL... 														>> %FullPathLog%
XCOPY %xcopySourceFullPath%\*.* 		%xcopyTargetFullPath% 	%xcopyCmdOption% 	>> %FullPathLog%
XCOPY %configSourceFullPath%\ERP10%envName%.txt	%xcopyTargetFullPath%\config	/S/R/C/F/Y			>> %FullPathLog%
del %xcopyTargetFullPath%\config\ERP10%envName%_MES.sysconfig
if "%cus%"=="" (
  ren "%xcopyTargetFullPath%\config\ERP10%envName%.txt" "ERP10%envName%_MES.sysconfig"
) else (
	setlocal DisableDelayedExpansion
	(for /F "delims=" %%a in (%xcopyTargetFullPath%\config\ERP10%envName%.txt) do (
	   SET "line=%%a"
	   setlocal EnableDelayedExpansion
	   if "!line:~0,20!"=="    <MESCustomMenuID" (
		  SET "line=    <MESCustomMenuID value="%cus%" />"
	   ) else if "!line:~0,11!"=="    <UserID" (
		  SET "line=    <UserID value="%uID%" />"
	   ) else if "!line:~0,13!"=="    <Password" (
		  SET "line=    <Password value="%pass%" />"
	   )
	   ECHO !line!
	   endlocal
	)) >> %xcopyTargetFullPath%\config\ERP10%envName%_MES.sysconfig
	del %xcopyTargetFullPath%\config\ERP10%envName%.txt
)
ECHO ****END %date% %time%****								 						>> %FullPathLog%

del %EpicorAlternateCache%\*.* /s /q /f