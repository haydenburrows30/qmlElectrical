!include "MUI2.nsh"

Name "Electrical Calculator"
OutFile "ElectricalCalculator_Setup.exe"
InstallDir "$PROGRAMFILES\ElectricalCalculator"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

Section "Install"
    SetOutPath "$INSTDIR"
    File "..\dist\ElectricalCalculator.exe"
    
    # Create start menu shortcut
    CreateDirectory "$SMPROGRAMS\ElectricalCalculator"
    CreateShortcut "$SMPROGRAMS\ElectricalCalculator\ElectricalCalculator.lnk" "$INSTDIR\ElectricalCalculator.exe"
    
    # Write uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
    Delete "$INSTDIR\ElectricalCalculator.exe"
    Delete "$INSTDIR\Uninstall.exe"
    RMDir "$INSTDIR"
    
    Delete "$SMPROGRAMS\ElectricalCalculator\ElectricalCalculator.lnk"
    RMDir "$SMPROGRAMS\ElectricalCalculator"
SectionEnd
