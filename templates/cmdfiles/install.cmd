@ECHO OFF
REM **************************************************************************************************************************
REM  PACKAGE NAME          : "<ENTER THE PACKAGE NAME>"
REM  SCRIPT MODIFIED DATE  : "<ENTER THE SCRIPT MODIFIED DATE DD-MM-YYYY>"
REM  SCRIPT VERSION        : 3.0
REM  SCRIPT DESCRIPTION    : This script will install the package "<PACKAGE NAME>" quietly
REM **************************************************************************************************************************

REM                                                       (Section 01)
REM ****************************************************************************************************************************
REM The section defines the set of variables to  be used in Install.CMD. Please include the variable which you are using in the script
REM ****************************************************************************************************************************

	SET PACKAGENAME=
	SET MSINAME1=
	SET MST1=
	SET MSIProdCode=
	SET uMSIProdCode=
	SET MSINAME2=
	SET MST2=
	SET MSIPSTCNFG=
	SET PRQ1=
	SET MSTPRQ1=
	SET EXENAME=
	SET CMDLNE=
	SET PROCNAME= 
	SET REBOOT=0
	SET CHECKCODE=
	SET APPBIT=32/64
	
    SET SFTpath=%~dp0
	IF "%SFTpath:~0,2%"=="\\" SET SFTpath=%SFTpath:\=\\%
	
REM                                                            (Section 02)
REM ********************************************************************************************************************************************************
REM Variables in the below section will be set depending on the value of the 32 bit Source or 64 bit source both from 32bit SCCM client and 64 bit SCCM client
REM *********************************************************************************************************************************************************

     GOTO APP%APPBIT%
   
     :APP32
   
	 SET PR=%ProgramFiles%
	 SET WUSA=%WINDIR%\system32\wusa.exe
	 SET REG=%WINDIR%\System32\reg.exe
	 SET MSG=%WINDIR%\System32\msg.exe
	 IF EXIST %WINDIR%\sysWow64\reg.exe  SET PR=%ProgramFiles(x86)%
     IF EXIST %WINDIR%\sysWow64\wusa.exe SET WUSA=%WINDIR%\sysWow64\wusa.exe
     IF EXIST %WINDIR%\sysWow64\reg.exe  SET REG=%WINDIR%\sysWow64\reg.exe
     IF EXIST %WINDIR%\Sysnative\msg.exe SET MSG=%WINDIR%\Sysnative\msg.exe
      GOTO START
	 
	 :APP64
			   
     SET PR=%ProgramFiles%
     SET MSG=%WINDIR%\System32\msg.exe
     SET WUSA=%WINDIR%\System32\wusa.exe
     SET REG=%WINDIR%\System32\reg.exe
     IF EXIST %WINDIR%\sysNative\reg.exe  SET PR=%ProgramW6432%
     IF EXIST %WINDIR%\sysNative\wusa.exe SET WUSA=%WINDIR%\sysNative\wusa.exe
     IF EXIST %WINDIR%\sysNative\reg.exe  SET REG=%WINDIR%\sysNative\reg.exe
     IF EXIST %WINDIR%\sysnative\msg.exe  SET MSG=%WINDIR%\Sysnative\msg.exe
	 
:START
REM                                                            (Section 03)
REM ********************************************************************************************************************************
REM Package Installation starts from here; Remove REM from below lines where ever applicable. 
REM *********************************************************************************************************************************
	echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
	
REM                                                             (Section 05)
REM *********************************************************************************************************************************
REM  Please use this section, if you are updating 99 packages and Re-installation of the current Package.
REM *********************************************************************************************************************************
 	 %REG% QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%MSIProdCode%" /v DisplayName
 	 IF NOT %ERRORLEVEL%==0 (GOTO INST1) ELSE (GOTO REINST)

REM											                    (Section 06)
REM ***********************************************************************************************************************************
REM Dependency application run-Check (e.g, during excel addin installation excel needs to be closed), place the script in this section.
REM This section should be used only when existing process of disabling RESTARTMANAGER in MSI does not work. If you are doing so, please remove REM from this section.
REM ***********************************************************************************************************************************
     TASKLIST /FI "IMAGENAME eq %ProcName%" 2>NUL | find /I /N "%ProcName%">NUL
	 IF NOT %ERRORLEVEL%==0 GOTO INST 
		%MSG% /TIME:0 * "%ProcName% is running:Installation needs %ProcName% to be closed before proceeding further.Please save your work and close the application , installation will start in 10 minutes."
		TIMEOUT /T 600 /NOBREAK
     TASKLIST /FI "IMAGENAME eq %ProcName%" 2>NUL | find /I /N "%ProcName%">NUL
	 IF NOT %ERRORLEVEL%==0 GOTO INST
 		%MSG% /TIME:0 * "%ProcName% is still running : Installation needs %procName% applications to be closed before proceeding further.Please save your work and close the applications in 15 minutes.Else the application will be force closed"
        TIMEOUT /T 900 /NOBREAK
      TASKLIST /FI "IMAGENAME eq %ProcName%" 2>NUL | find /I /N "%ProcName%">NUL
	 IF NOT %ERRORLEVEL%==0 GOTO INST
		 taskkill /F /IM %ProcName%
		
:INST

REM											                         (Section 7)	
REM ************************************************************************************************************************************************
REM Dependency Install (to differentiate the message in the SCCM_PackageHistory file , Instead of Start "Dependency Start" and "Dependency END OK" is being Used)
REM Remove REM word from the beginning of below lines in this section if you want install one or more Dependencies before installing main Package
REM ************************************************************************************************************************************************
	 echo %DATE% %TIME% ; %PRQ1% ; %~nx0 ; DEPENDENDCY INSTALLATION START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
	 MSIEXEC.EXE /I "%~dp0%PRQ1%.msi" TRANSFORMS="%~dp0%MSTPRQ1%.mst" /QB-! /l*v "c:\Install\%PRQ1%.MSI.log"
	     IF NOT %ERRORLEVEL%==0 ( IF NOT %ERRORLEVEL%==1641 ( IF NOT %ERRORLEVEL%==3010 GOTO GOUT ) )
 		 SET LERROR=%ERRORLEVEL%
	     IF %LERROR%==3010 SET /a REBOOT=%REBOOT%+1
	     IF %LERROR%==1641 SET /a REBOOT=%REBOOT%+1
     echo %DATE% %TIME% ; %PRQ1% ; %~nx0 ; DEPENDENCY INSTALLATION END OK: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"


REM												         	         (Section 8)
REM ***********************************************************************************************************************************************
REM UPGRADE and also un-installation of Older version packages (This section should be used only if MSI Upgrade does not work and you need to un-install existing product using command line )
REM ***********************************************************************************************************************************************
 	 REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%uMSIProdCode%" /v DisplayName
	     IF NOT %ERRORLEVEL%==0 GOTO INST1
     echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; OLDER VERSION INSTALLATION START: %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
	 MSIEXEC.EXE /X %uMSIProdCode% /QB-! /l*v "c:\Install\OLD_%PACKAGENAME%_Uninstall.MSI.log"
		 IF NOT %ERRORLEVEL%==0 ( IF NOT %ERRORLEVEL%==1605 (IF NOT %ERRORLEVEL%==1641 ( IF NOT %ERRORLEVEL%==3010 GOTO GOUT ) ) )
		 SET LERROR=%ERRORLEVEL%
		 IF %LERROR%==3010 SET /a REBOOT=%REBOOT%+1
		 IF %LERROR%==1641 SET /a REBOOT=%REBOOT%+1
	echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; OLDER VERSION INSTALLATION END OK: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"


REM												                (Section 9)
REM **********************************************************************************************************************************************
REM Use this section for Installing Virtual Packages
REM **********************************************************************************************************************************************
	 echo %DATE% %TIME% ; %MSINAME1% ; %~nx0 ;INSTALLATION START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
	 MSIEXEC.EXE /I "%~dp0%MSINAME1%.msi" ARPNOREMOVE=1 /QB-! MODE=STREAMING OVERRIDEURL="%SFTpath%%MSINAME1%.sft" LOAD=TRUE /l*v "C:\Install\%MSINAME1%.log"
		 IF NOT %ERRORLEVEL%==0 ( IF NOT %ERRORLEVEL%==1641 ( IF NOT %ERRORLEVEL%==3010 GOTO GOUT ) )
		 SET LERROR=%ERRORLEVEL%
		 IF %LERROR%==3010 SET /a REBOOT=%REBOOT%+1
		 IF %LERROR%==1641 SET /a REBOOT=%REBOOT%+1
	 echo %DATE% %TIME% ; %MSINAME1% ; %~nx0 ; INSTALLATION END OK: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
 
REM												               (Section 10)
REM *********************************************************************************************************************************************************
REM  Set-up Installation; Please remove REM from below section if package installation is trigged silently with EXE
REM	 Please capture proper return code for set-up installation and put value accordingly; Only 0 is used here as default,check the vendor site for ErrorCodes
REM **********************************************************************************************************************************************************

	 echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; SETUP SILENT INSTALLATION START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
     %MSG% /TIME:15 * "Silent installation of %PACKAGENAME% is in progress and it would take approx 60 minutes . Once installation is successfully completed, you will get a confirmation message."
	 "%~dp0%EXENAME%.exe" "%CMDLNE%"
	     IF NOT %ERRORLEVEL%==0 ( IF NOT %ERRORLEVEL%==xx ( IF NOT %ERRORLEVEL%==yy GOTO GOUT ) )
		 SET LERROR=%ERRORLEVEL%
		 IF %LERROR%==xx SET /a REBOOT=%REBOOT%+1
		 IF %LERROR%==xx SET /a REBOOT=%REBOOT%+1
     echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; SETUP SILENT INSTALLATION END OK: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"



:INST1
REM												            (Section 11)
REM ************************************************************************************************************************************
REM  MSI Installation; Please UN-check REM from below MSINAME2 section if you have multiple MSI; add another section for more than 2 MSI
REM ************************************************************************************************************************************
     echo %DATE% %TIME% ; %MSINAME1% ; %~nx0 ; INSTALLATION START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
		MSIEXEC.EXE /I "%~dp0%MSINAME1%.msi" TRANSFORMS="%~dp0%MST1%.mst" /QB-! /l*v "c:\Install\%MSINAME1%.MSI.log"		
	     IF NOT %ERRORLEVEL%==0 ( IF NOT %ERRORLEVEL%==1641 ( IF NOT %ERRORLEVEL%==3010 GOTO GOUT ) )
		 SET LERROR=%ERRORLEVEL%
		 IF %LERROR%==3010 SET /a REBOOT=%REBOOT%+1
	     IF %LERROR%==1641 SET /a REBOOT=%REBOOT%+1
     echo %DATE% %TIME% ; %MSINAME1% ; %~nx0 ; INSTALLATION END OK: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"


REM													        (Section 12)
REM ***************************************************************************************************************************************************************************************
REM If you have user specific files to be repaired, please use this section to copy the installer MSI in Windows installer cache folder, Please make the MSI install section below as remark
REM ****************************************************************************************************************************************************************************************
	 echo %DATE% %TIME% ; %MSINAME1% ; %~nx0 ; INSTALLATION START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
         XCOPY /Y /I /E /S "%~dp0%PACKAGENAME%" "%WinDir%\Installer\%PACKAGENAME%"
	     MSIEXEC.EXE /I "%WinDir%\Installer\%PACKAGENAME%\%MSINAME1%.msi" TRANSFORMS="%WinDir%\Installer\%PACKAGENAME%\%MST1%.mst" /QB-! /l*v "c:\Install\%MSINAME1%.MSI.log"
	     IF NOT %ERRORLEVEL%==0 ( IF NOT %ERRORLEVEL%==1641 ( IF NOT %ERRORLEVEL%==3010 GOTO GOUT ) )
	     SET LERROR=%ERRORLEVEL%
		 IF %LERROR%==3010 SET /a REBOOT=%REBOOT%+1
	     IF %LERROR%==1641 SET /a REBOOT=%REBOOT%+1
	 echo %DATE% %TIME% ; %MSINAME1% ; %~nx0 ; INSTALLATION END OK: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"

:REINST
REM													         (Section 13)
REM ****************************************************************************************************************************************
REM  Re-installation (for 99 Packages Only; Remove REM word from the beginning of below lines if you are working on 99 Package). Don't change MSI name.
REM ****************************************************************************************************************************************
	 echo %DATE% %TIME% ; %MSINAME1% ; %~nx0 ; INSTALLATION START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
		 REG ADD "HKEY_CLASSES_ROOT\Installer\Products\%CHECKCODE%" /v "Transforms" /t "REG_SZ" /d "%windir%\Installer\%MSIProdCode%\%MSTNAME1%.mst" /f
         DEL /F /Q "%WINDIR%\Installer\%MSIProdCode%\%MSTNAME1%.mst"
         COPY /Y "%~dp0%MSTNAME1%.mst" "%WINDIR%\Installer\%MSIProdCode%\%MSTNAME1%.mst"
	     MSIEXEC.EXE /I "%~dp0%MSINAME1%.msi" REINSTALL="ALL" REINSTALLMODE=VOMUS /QB-! /l*v "c:\Install\%MSINAME1%.MSI.log"
         MSIEXEC.EXE /I "%~dp0%MSINAME1%.msi" TRANSFORMS="%~dp0%MST1%.mst" REINSTALL="ALL" REINSTALLMODE=VOMUS /QB-! /l*v "c:\Install\%MSINAME1%.MSI.log"
		 IF NOT %ERRORLEVEL%==0 ( IF NOT %ERRORLEVEL%==1641 ( IF NOT %ERRORLEVEL%==3010 GOTO GOUT ) )
		 SET LERROR=%ERRORLEVEL%
		 IF %LERROR%==3010 SET /a REBOOT=%REBOOT%+1
		 IF %LERROR%==1641 SET /a REBOOT=%REBOOT%+1
	 echo %DATE% %TIME% ; %MSINAME1% ; %~nx0 ; INSTALLATION END OK: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"

REM													        (Section 14)
REM ****************************************************************************************************************************************
REM   MSI Post-configuration; Please remove REM from below section if you have MSI post-configuration to be installed
REM ****************************************************************************************************************************************
	 echo %DATE% %TIME% ; %MSIPSTCNFG% ; %~nx0 ; INSTALLATION START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
		 MSIEXEC.EXE /I "%~dp0%MSIPSTCNFG%.msi" TRANSFORMS= /QB-! /l*v "c:\Install\%MSIPSTCNFG%.MSI.log"
		 IF NOT %ERRORLEVEL%==0 ( IF NOT %ERRORLEVEL%==1641 ( IF NOT %ERRORLEVEL%==3010 GOTO GOUT ) )
		 SET LERROR=%ERRORLEVEL%
		 IF %LERROR%==3010 SET /a REBOOT=%REBOOT%+1
		 IF %LERROR%==1641 SET /a REBOOT=%REBOOT%+1
	 echo %DATE% %TIME% ; %MSIPSTCNFG% ; %~nx0 ; INSTALLATION END OK: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"

REM													       (Section 15)
REM *******************************************************************************************************************************************************************************
REM   PostConfiguration except MSI Post-CONFIG (This section should be used only when its not possible through MSI); e,g: if you have another language (Chinese) registry to import.
REM *******************************************************************************************************************************************************************************
       REGEDIT /S xyz.reg
	   
	   

REM													       (Section 16)
REM *******************************************************************************************************************************************************************************
REM  Use this Section for installing Modern Application (Side Loading)
REM *******************************************************************************************************************************************************************************	   
	   
	 %MSG% /TIME:7 * "%PackageName%: Silent installation of the application is in progress. Once installation is successfully completed, you will get a confirmation message."

      PowerShell -command "add-appxpackage '%~dp0Training_1.0.0.18_AnyCPU_Debug.appx'"
      SET /a LERROR=%ERRORLEVEL%
      IF NOT %LERROR%==0 GOTO GOUT

     %MSG% /TIME:0 * "%PackageName%: Installation is completed"  


REM													       (Section 17)
REM *******************************************************************************************************************************************************************************
REM  ARP TATTO0ING
REM *******************************************************************************************************************************************************************************	  


	%REG% ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\%PackageName%" /v "DisplayName" /t REG_SZ /d "%PackageName%" /F
	%REG% ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\%PackageName%" /v "NoModify" /t REG_DWORD /d "1" /F
	%REG% ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\%PackageName%" /v "NoRemove" /t REG_DWORD /d "1" /F
	%REG% ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\%PackageName%" /v "UninstallString" /t REG_SZ /d "Nothing" /F
REM	%REG% ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\%PackageName%" /v "SystemComponent" /t REG_DWORD /d "1" /F
REM	%REG% ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\%MSIProdCode%" /v "COREPackageName" /t REG_SZ /d "%PackageName%" /F 



REM													       (Section 18)
REM **************************************************************************************************************************************************
REM Below section is used to return actual Error code to SCCM, Displaying Message and create SCCM_PackageHistory.log file entry for install completion
REM ****************************************************************************************************************************************************
 :END

     IF %REBOOT% GTR 0 %MSG% /TIME:0 * "%PACKAGENAME%: Machine needs to REBOOT in order to finish software installation. Please REBOOT as soon as possible" 
		 IF %REBOOT% GTR 0 GOTO REBOOTRecord
	 
	 echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; END OK; Execution Return Code: %LERROR%; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
	     %MSG% /TIME:0 * "%PACKAGENAME%: Please Logoff and Login again to finish installation of the application"
	     EXIT /B %LERROR%
	

REM                                                       (Section 19)
REM *******************************************************************************************************************************************************
REM  In this Section REBOOT request will be sent to SCCM
REM *******************************************************************************************************************************************************
:REBOOTRecord	
	echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; END OK; Execution Return Code: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
	     EXIT /B 3010
	

REM                                                       (Section 20)
REM ***********************************************************************************************************************************************************
REM This Section is used to prompt message to user in case of failure of application installation
REM **********************************************************************************************************************************************************
:GOUT 
	 echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; EXIT; Execution Return Code: %ERRORLEVEL%; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
	     EXIT /B %ERRORLEVEL%
		 

REM                                                       (Section 21)	 
REM **************************************************************************************************************************************************************
REM This Section executes if higher version of application is already installed on the machine
REM **************************************************************************************************************************************************************
:SKIPINST
	 echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; EXIT; Higher version of package is already installed   ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
	     EXIT /B 0
	
REM *****************************************************************************************************************
REM  End of Installation Script
REM ******************************************************************************************************************

