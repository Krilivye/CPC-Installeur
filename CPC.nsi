#---------------------------------------------------------------------------------------------------
#Chargement du system NSIS en mode "modern GUI"
!define PRODUCT_NAME "CPC-Arma3"
!define PRODUCT_VERSION "1.0"
!define PRODUCT_PUBLISHER "Krilivye pour CPC"
!define PRODUCT_WEB_SITE "http://forum.canardpc.com/threads/77056-Serveur-ARMA-3-Conflit-de-canard-coop-ACRE-le-jeudi-mettez-vos-dispo-sur-Doodle"

; MUI 1.67 compatible ------
!include "MUI.nsh"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "CPCicon.ico"

; Welcome page
!define MUI_WELCOMEFINISHPAGE_BITMAP "CPCWelcome.bmp"
!insertmacro MUI_PAGE_WELCOME

; Directory page
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE "dirLeave"
!insertmacro MUI_PAGE_DIRECTORY
DirText "CPC Arma III community pack necessite le repertoire d'arma III" "Repertoire d'Arma III" "Chercher" "Rechercher le repertoire d'arma III"

; Instfiles page
!insertmacro MUI_PAGE_INSTFILES
ShowInstDetails show

; Language files
!insertmacro MUI_LANGUAGE "French"

#---------------------------------------------------------------------------------------------------

#Macro verifie qu'une clef existe dans le registre 1 si oui, 0 si non
!macro IfKeyExists ROOT MAIN_KEY KEY
push $R0
push $R1
 
!define Index 'Line${__LINE__}'
 
StrCpy $R1 "0"
 
"${Index}-Loop:"
; Check for Key
EnumRegKey $R0 ${ROOT} "${MAIN_KEY}" "$R1"
StrCmp $R0 "" "${Index}-False"
  IntOp $R1 $R1 + 1
  StrCmp $R0 "${KEY}" "${Index}-True" "${Index}-Loop"
 
"${Index}-True:"
;Return 1 if found
push "1"
goto "${Index}-End"
 
"${Index}-False:"
;Return 0 if not found
push "0"
goto "${Index}-End"
 
"${Index}-End:"
!undef Index
exch 2
pop $R0
pop $R1
!macroend

!include x64.nsh

Function dirLeave
  GetInstDirError $0
  ${Switch} $0
    ${Case} 0
	  IfFileExists "$INSTDIR\arma3.exe" validArmaDir novalidArmaDir
	  validArmaDir:
		setOutPath $INSTDIR
		Goto endValid
	  novalidArmaDir:
		MessageBox MB_ICONSTOP  "Le repertoire ne contient pas le fichier arma3.exe!"
		Abort
      ${Break}
    ${Case} 1
      MessageBox MB_ICONSTOP  "invalid installation directory!"
      Abort
      ${Break}
    ${Case} 2
      MessageBox MB_ICONSTOP  "not enough free space!"
      Abort
      ${Break}
  ${EndSwitch}
  endValid:
FunctionEnd

#---------------------------------------------------------------------------------------------------
SetOverwrite on


# Nom de l'installeur
Name "CPC Arma III"
OutFile "cpc-arma3.exe"


 Function .onInit

	IfFileExists $EXEDIR\CPCWinSCP.txt fromEXEPath pathFromRegistry
	fromEXEPath:
		StrCpy $INSTDIR $EXEDIR -10
		Goto endInit
	pathFromRegistry:
		ReadRegStr $R1 HKCU "Software\Valve\Steam" SourceModInstallPath
		StrCpy $INSTDIR "$R1" -10
		StrCpy $INSTDIR "$INSTDIR\common\Arma 3\"
		Goto endInit
	endInit:
		setOutPath $INSTDIR
		Return
		
FunctionEnd


# Level Admin necessaire pour les différentes installations win vista+
RequestExecutionLevel admin


#Selection du repertoire d'arma 3
Section

	#Repertoire par defaut se base sur la fonction .onInit
	
	StrCpy $R9 "32"
	${If} ${RunningX64}
		StrCpy $R9 "64"
		DetailPrint "Vous avez un processeur $R9 bit"
	${EndIf}
	CreateDirectory $INSTDIR\CPCInstall
	File /oname=CPCInstall\WinSCP.com WinSCP.com
	File /oname=CPCInstall\WinSCP.exe WinSCP.exe
	File /oname=CPCInstall\cpc_aia.bat cpc_aia.bat


    IfFileExists $INSTDIR\CPCInstall\CPC-Launcher.exe updateLauncher installLauncher
    
    installLauncher:
        File /oname=CPCInstall\CPC-Launcher.exe CPC-Launcher.exe
        File /oname=CPCInstall\CPC-Launcher.exe.config CPC-Launcher.exe.config
        CreateDirectory $INSTDIR\CPCInstall\LauncherFiles
        File /oname=CPCInstall\LauncherFiles\allinarma LauncherFiles\allinarma
        File /oname=CPCInstall\LauncherFiles\cpcarma3 LauncherFiles\cpcarma3
        File /oname=CPCInstall\LauncherFiles\cpcmcc LauncherFiles\cpcmcc
        File /oname=CPCInstall\LauncherFiles\cpcts LauncherFiles\cpcts
        File /oname=CPCInstall\LauncherFiles\cpcupdate LauncherFiles\cpcupdate
        Goto updateLauncher
        
    updateLauncher:

 

	
SectionEnd

#Installation de Teamspeak 3
Section "Prerequis"
	
	#Check TS3
	!insertmacro IfKeyExists HKCR "ts3file\shell\open\" "command"
	Pop $R0
	IntCmp $R0 0 installTS3 endTS3 endTS3
	
	installTS3:
		MessageBox MB_YESNO "Installer TeamSpeak3?" /SD IDYES IDNO endTS3
			DetailPrint "Téléchargement de TeamSpeak3"
			inetc::get /caption "Téléchargement de TeamSpeak 3" "http://ftp.4players.de/pub/hosted/ts3/releases/3.0.10.1/TeamSpeak3-Client-win$R9-3.0.10.1.exe" "$INSTDIR\ts3.exe"
			Pop $0
			StrCmp $0 "OK" execTS
			MessageBox MB_OK|MB_ICONEXCLAMATION "Impossible de trouver l'installeur TeamSpeak! Allez le chercher sur http://www.teamspeak.com/?page=downloads Fin de l'instalation." /SD IDOK
			Abort
			execTS:
				ExecWait '$INSTDIR\ts3.exe'
				Delete $INSTDIR\ts3.exe
			Goto endTS3
	endTS3:
		DetailPrint "Vous avez TeamSpeak 3 d'installé... on continue"
		# Rien à faire on passe à la suite
SectionEnd

#Installation du pack CPC
Section "CPC"
	IfFileExists $INSTDIR\CPCInstall\CPCWinSCP.txt updateCPC dlCPC
	dlCPC:
		DetailPrint "Téléchargement du pack CPC Arma III"
		inetc::get /caption "Téléchargement du pack CPC Arma III" "ftp://addons:coin@188.165.212.111/FullPack/CPC.7z" "$INSTDIR\CPC.7z"
		Pop $0
		StrCmp $0 "OK" unZipCPC
		MessageBox MB_OK|MB_ICONEXCLAMATION "Erreur le fichier ftp://addons:coin@188.165.212.111/FullPack/CPC.7z n'est pas présent! Fin de l'instalation." /SD IDOK
		DetailPrint "Problèmes lors du téléchargement du pack CPC Arma III. Installation annulée"
		Abort
	    unZipCPC:
			Nsis7z::ExtractWithDetails "CPC.7z" "Installation du pack CPC Arma III %s..."
			Delete $INSTDIR\CPC.7z
			
			Goto updateCPC
	updateCPC:
		DetailPrint "Mise à jour du pack CPC Arma III"
		
		CreateDirectory $INSTDIR\@ACRE
		CreateDirectory $INSTDIR\@CBA_A3
		CreateDirectory $INSTDIR\@cpc_core
		CreateDirectory $INSTDIR\@cpc_util
		CreateDirectory $INSTDIR\@cpc_iles
		CreateDirectory $INSTDIR\@JayArma2Lib
		CreateDirectory $INSTDIR\userconfig
		CreateDirectory $INSTDIR\@AllInArma
		
		File /oname=CPCInstall\CPCWinSCP.txt CPCWinSCP.txt
		NSExec::ExecToLog "$INSTDIR\CPCInstall\WinSCP.com /script=CPCInstall\CPCWinSCP.txt"
		Delete "$INSTDIR\CPCInstall\WinSCP.com"
		Delete "$INSTDIR\CPCInstall\WinSCP.exe"

		
		# racourci pour CPC Launcher avec les bon paramètres
		CreateShortCut "$DESKTOP\CPC-Arma3.lnk" "$INSTDIR\CPCInstall\CPC-Launcher.exe"
		ShellLink::SetRunAsAdministrator $DESKTOP\CPC-Arma3.lnk
		WriteRegStr HKLM "Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\layers" \
		"$INSTDIR\arma3.exe" "RUNASADMIN"
			
		CopyFiles "$EXEDIR\cpc-arma3.exe" "$INSTDIR\CPCInstall\cpc-arma3.exe"
		
		DetailPrint "Fin de la mise à jour"
SectionEnd

#Configuration de TS3
Section "Config TS3"
	
	#copy du plugin acre
	DetailPrint "Installation du plugin ACRE sur TeamSpeak 3"
	ReadRegStr $R2 HKCR "ts3file\shell\open\command" ""
	StrCpy $R3 "$R2" -26
	StrCpy $R4 $R3 "" 1
	StrCpy $R5 "$R4\plugins"
	IfFileExists '$R5\acre_win$R9.dll' noACRE copyACRE
	copyACRE:
		DetailPrint "Installation du plugin ACRE sur TeamSpeak 3"
		CopyFiles '$INSTDIR\@ACRE\plugin\acre_win$R9.dll' '$R5'
		# racourci pour ts3
		WriteRegStr HKLM "Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\layers" \
		"$R4\ts3client_win$R9.exe" "RUNASADMIN"
	noACRE:
		DetailPrint "ACRE est déjà installé sur TeamSpeak 3: Mise à jour"
		CopyFiles '$INSTDIR\@ACRE\plugin\acre_win$R9.dll' '$R5'
SectionEnd