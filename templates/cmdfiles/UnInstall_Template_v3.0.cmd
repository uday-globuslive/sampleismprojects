@ECHO OFF

REM **************************************************************************************************************************
REM  PACKAGE NAME          : "<ENTER THE PACKAGE NAME>"
REM  SCRIPT VERSION        : 3.0
REM  PACKAGE DESCRIPTION   : This script will UNINSTALL the package "<PACKAGE NAME>" quietly
REM **************************************************************************************************************************
					
REM													(Section 01)
REM **************************************************************************************************************************
REM Set Variables for the execution; Please use complete command line including LOGFILE creation in CMDLNE variable.Please include the variable which you are using in the script
REM Setting MSG, REG paths depending on the 32 bit and 64 bit Architecture
REM **************************************************************************************************************************

	Set PACKAGENAME=
	SET vProdCode=
	SET MSINAME1=
	SET MSIPRODCODE1=
	SET MSINAME2=
	SET MSIPRODCODE2=
	SET MSIPSTCNFG=
	SET PSTCFGPRODCODE=
	SET PRQ1=
	SET PRQCode1=
	SET TRANSFORMS=
	SET EXENAME=
	SET CMDLNE=
	SET PROCNAME= 
	SET REBOOT=0
	SET Coun1= 0
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
     IF EXIST %WINDIR%\Sysnative\msg.exe  SET MSG=%WINDIR%\Sysnative\msg.exe
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
 
REM	                                                     (Section 03)
REM ********************************************************************************************************************************
REM Application UN-Installation starts from here; Remove REM from below lines where ever applicable.
REM ********************************************************************************************************************************
	echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
	
REM                                                      (Section 04)
REM **************************************************************************************************************************
REM Use this section for Virtual Application
REM **************************************************************************************************************************	
	 echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; UNINSTALLATION START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
	     MSIEXEC.EXE /x %vProdCode% /QB-! /l*v "C:\Install\%PACKAGENAME%_UnInstall.MSI.log"
		 IF NOT %ERRORLEVEL%==0 ( IF NOT %ERRORLEVEL%==1641 (IF NOT %ERRORLEVEL%==1605 ( IF NOT %ERRORLEVEL%==3010 GOTO GOUT ) ) )
		 SET LERROR=%ERRORLEVEL%
		 IF %LERROR%==3010 SET /a REBOOT=%REBOOT%+1
		 IF %LERROR%==1641 SET /a REBOOT=%REBOOT%+1
	 echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; UNINSTALLATION END OK: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"

REM											           (Section 05)
REM **************************************************************************************************************************
REM Dependency application run-Check (e.g, during excel ADDIN UNINSTALLATION excel needs to be closed), place the script in this section.
REM This section should be used only when existing process of disabling RESTARTMANAGER in MSI does not work. If you are doing so, please remove REM from this section.
REM **************************************************************************************************************************
	        TASKLIST /FI "IMAGENAME eq %ProcName%" 2>NUL | find /I /N "%ProcName%">NUL
	 If NOT %ERRORLEVEL%==0 GOTO UNINST 
		%MSG% /TIME:0 * "%ProcName% is running:UnInstallation needs %ProcName% to be closed before proceeding further.Please save your work and close the application , Uninstallation will start in 10 minutes."
		TIMEOUT /T 600 /NOBREAK
     TASKLIST /FI "IMAGENAME eq %ProcName%" 2>NUL | find /I /N "%ProcName%">NUL
		If NOT %ERRORLEVEL%==0 GOTO UNINST
 		%MSG% /TIME:0 * "%ProcName% is still running and Installation will Abort now . To Uninstall the application again, Close %ProcName% and navigate to Start Menu > Control Panel > Run Advertised Programs, Select the application and Click on Run"
 		echo %DATE% %TIME% ; %PackageName% ; %~nx0 ; Aborted - Dependent application (%ProcName%) needs to be closed before installation ; %COMPUTERNAME% ; %USERNAME% ; >> "c:\Install\SCCM_PackageHistory.log"
      EXIT /B 1

:UNINST
	  
REM														(Section 06)
REM ****************************************************************************************************************************************
REM   MSI Post-configuration; Please remove REM from below section if you have MSI post-configuration to be un-installed
REM ****************************************************************************************************************************************
	 echo %DATE% %TIME% ; %MSIPSTCNFG% ; %~nx0 ; UNINSTALLATION START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
		MSIEXEC.EXE /x %PSTCFGPRODCODE% /QB-! /l*v "c:\Install\%MSIPSTCNFG%_Uninstall.MSI.log"
			 IF NOT %ERRORLEVEL%==0 ( IF NOT %ERRORLEVEL%==1641 ( IF NOT %ERRORLEVEL%==1605 ( IF NOT %ERRORLEVEL%==3010 GOTO GOUT ) ) )
 		     SET LERROR=%ERRORLEVEL%
			 IF %LERROR%==3010 SET /a REBOOT=%REBOOT%+1
			 IF %LERROR%==1641 SET /a REBOOT=%REBOOT%+1
	 echo %DATE% %TIME% ; %MSIPSTCNFG% ; %~nx0 ; UNINSTALLATION END OK: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"

REM														(Section 07)
REM **************************************************************************************************************************
REM Dependency UN-Install (to differentiate the message in the SCCM_PackageHistory file , Instead of Start "Dependency Start" and "Dependency END OK" is being Used)
REM Remove REM word from the beginning of below lines in this section if you want Dependency to UN-Install before UN-installing main Package
REM **************************************************************************************************************************
	 echo %DATE% %TIME% ; %PRQ1% ; %~nx0 ; UNINSTALLATION START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
		 MSIEXEC.EXE /x %PRQCode1% /QB-! /l*v "c:\Install\%PRQ1%_Uninstall.MSI.log"
			 IF NOT %ERRORLEVEL%==0 ( IF NOT %ERRORLEVEL%==1641 ( IF NOT %ERRORLEVEL%==1605 ( IF NOT %ERRORLEVEL%==3010 GOTO GOUT ) ) )
 		     SET LERROR=%ERRORLEVEL%
			 IF %LERROR%==3010 SET /a REBOOT=%REBOOT%+1
			 IF %LERROR%==1641 SET /a REBOOT=%REBOOT%+1
	 echo %DATE% %TIME% ; %PRQ1% ; %~nx0 ; UNINSTALLATION END OK :%LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"

REM														(Section 08)
REM **************************************************************************************************************************
REM  SETUP Un-Installation; Please remove REM from below section if you are proceeding with EXE UN-installation
REM	 Please capture proper return code for SETUP UN-installation and put value accordingly; Only 0 is used here as default
REM ***************************************************************************************************************************
	 echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; SETUP SILENT UNINSTALLATION START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
		 "%~dp0%EXENAME%.exe" "%CMDLNE%"
			IF NOT %ERRORLEVEL%==0 ( IF NOT %ERRORLEVEL%==xx ( IF NOT %ERRORLEVEL%==yy GOTO GOUT ) )
			SET LERROR=%ERRORLEVEL%
			IF %LERROR%==xx SET /a REBOOT=%REBOOT%+1
		    IF %LERROR%==xx SET /a REBOOT=%REBOOT%+1
	 echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; SETUP SILENT UNINSTALLATION END OK: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
 
REM														 (Section 09)
REM **************************************************************************************************************************
REM  MSI Un-Installation; Please use MSINAME2 section if you have multiple MSI; add another section for more than 2 MSI
REM ***************************************************************************************************************************
	echo %DATE% %TIME% ; %MSINAME1% ; %~nx0 ; UNINSTALLATION START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
		MSIEXEC.EXE /x %MSIPRODCODE1% /QB-! /l*v "c:\Install\%MSINAME1%_Uninstall.MSI.log"
			IF NOT %ERRORLEVEL%==0 ( IF NOT %ERRORLEVEL%==1641 ( IF NOT %ERRORLEVEL%==1605 ( IF NOT %ERRORLEVEL%==3010 GOTO GOUT ) ) )
			SET LERROR=%ERRORLEVEL%
			IF %LERROR%==3010 SET /a REBOOT=%REBOOT%+1
			IF %LERROR%==1641 SET /a REBOOT=%REBOOT%+1
	echo %DATE% %TIME% ; %MSINAME1% ; %~nx0 ; UNINSTALLATION END OK: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"

	
REM														(Section 10)
REM ****************************************************************************************************************************************
REM  Un-installation (for 99 Packages Only; Remove REM word from the beginning of below lines if you are working on 99 Package)
REM ****************************************************************************************************************************************
	echo %DATE% %TIME% ; %MSINAME1% ; %~nx0 ; UNINSTALLATION START ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
		 MSIEXEC.EXE /x %MSIPRODCODE1% /QB-! /l*v "c:\Install\%MSINAME1%_Uninstall.MSI.log"
			 IF NOT %ERRORLEVEL%==0 ( IF NOT %ERRORLEVEL%==1641 ( IF NOT %ERRORLEVEL%==1605 ( IF NOT %ERRORLEVEL%==3010 GOTO GOUT ) ) )
		     SET LERROR=%ERRORLEVEL%
		     IF %LERROR%==3010 SET /a REBOOT=%REBOOT%+1
			 IF %LERROR%==1641 SET /a REBOOT=%REBOOT%+1
	echo %DATE% %TIME% ; %MSINAME1% ; %~nx0 ; UNINSTALLATION END OK: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"

REM														(Section 11)
REM ***************************************************************************************************************************************************************
REM If you have copied the package to Windows\Installer folder, please remove REM from below line. This will take care of deleting package folder after un-install is over.
REM ****************************************************************************************************************************************************************
      RD  /S /Q "%WinDir%\Installer\%PACKAGENAME%"

REM														(Section 12)
REM ***************************************************************************************************************************************************************
REM If you have copied the package to Windows\Installer folder, please remove REM from below line. This will take care of deleting package folder after un-install is over.
REM ****************************************************************************************************************************************************************	  
	  
      %MSG% /TIME:7 * "%PackageName%: Silent Un-Installation of the application is in progress. Once the Un-Installation is successfully completed, you will get a confirmation message."

        PowerShell -command "get-appxpackage | where {$_.Name -eq '14113f40-f7e5-402e-842a-0a34f3083d37'} | remove-appxpackage"
        SET /a LERROR=%ERRORLEVEL%
        IF NOT %LERROR%==0 GOTO GOUT

      %MSG% /TIME:0 * "%PackageName%: Un-installation is completed"	  
	  

REM													       (Section 13)
REM *******************************************************************************************************************************************************************************
REM  ARP TATTOING Removal
REM *******************************************************************************************************************************************************************************	    
	
       %REG% DELETE "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\%PackageName%" /F
		  
	  
REM														(Section 14)
REM ***************************************************************************************************************************************************
REM Below section is used to return actual error code to SCCM, Displaying Message and create SCCM_PackageHistory.log file entry for Un install completion
REM ****************************************************************************************************************************************************

         IF %REBOOT% GTR 0 %MSG% /TIME:0 * "%PACKAGENAME%:The application Un-installation needs system REBOOT. Please REBOOT your machine to complete the un-installation."
         IF %REBOOT% GTR 0 GOTO REBOOTRECORD	
	     echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; END OK; Execution Return Code: %LERROR% ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
    	 %MSG% /TIME:0 * "%PACKAGENAME%: Please Logoff and Login again to finish un-installation of the application"
	     EXIT /B %LERROR%
	 
REM														(Section 15)
REM ************************************************************************************************************************************************************
REM  In this Section REBOOT request will be sent to SCCM
REM ************************************************************************************************************************************************************
:REBOOTRECORD
	 echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; END OK; Execution Return Code: %LERROR%  ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
	     EXIT /B 3010
	

REM														(Section 16)
REM *******************************************************************************************************
REM This Section is used to prompt message to user in case of failure of application installation
REM ********************************************************************************************************
:GOUT
REM %MSG% /TIME:0 * "%PACKAGENAME%:UnInstallation has been aborted with an unexpected error, Please contact Local Helpdesk for further Assistance"
	 echo %DATE% %TIME% ; %PACKAGENAME% ; %~nx0 ; EXIT; Execution Return Code: %ERRORLEVEL%  ; %COMPUTERNAME% ; %USERNAME% >> "c:\Install\SCCM_PackageHistory.log"
	     EXIT /B %ERRORLEVEL%
	
	
REM *****************************************************************************************************************
REM  End of /UN-Installation Script
REM ******************************************************************************************************************
