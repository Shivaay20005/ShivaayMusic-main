[Setup]
AppId=53484956-4141-5980-8105-374300000000
AppVersion=1.0.7
AppName=ShivaayMusic
AppVerName=ShivaayMusic
AppPublisher=shivaay20005
AppPublisherURL=https://github.com/shivaay20005/ShivaayMusic-Windows-release
AppSupportURL=https://github.com/shivaay20005/ShivaayMusic-Windows-release
AppUpdatesURL=https://github.com/shivaay20005/ShivaayMusic-Windows-release
DefaultDirName={autopf}\shivaaymusic
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=shivaaymusic
Compression=lzma
SolidCompression=yes
SetupIconFile=..\..\..\windows\runner\resources\app_icon.ico
WizardStyle=modern
PrivilegesRequired=lowest
LicenseFile=..\..\..\LICENSE
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\..\build\windows\x64\runner\Release\shivaaymusic.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\ShivaayMusic"; Filename: "{app}\shivaaymusic.exe"
Name: "{autodesktop}\ShivaayMusic"; Filename: "{app}\shivaaymusic.exe"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\shivaay.exe"; ValueType: string; ValueName: ""; ValueData: "{app}\shivaaymusic.exe"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\shivaay.exe"; ValueType: string; ValueName: "Path"; ValueData: "{app}"; Flags: uninsdeletekey

; Alias: shivaaymusic
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\shivaaymusic.exe"; ValueType: string; ValueName: ""; ValueData: "{app}\shivaaymusic.exe"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\shivaaymusic.exe"; ValueType: string; ValueName: "Path"; ValueData: "{app}"; Flags: uninsdeletekey

; Alias: shivaay music (Space supported)
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\shivaay music.exe"; ValueType: string; ValueName: ""; ValueData: "{app}\shivaaymusic.exe"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\shivaay music.exe"; ValueType: string; ValueName: "Path"; ValueData: "{app}"; Flags: uninsdeletekey

[Run]
Filename: "{app}\shivaaymusic.exe"; Description: "{cm:LaunchProgram,{#StringChange('ShivaayMusic', '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Setup]
UninstallDisplayIcon={app}\shivaaymusic.exe

[Code]
// Hide the specific filename being extracted (e.g. .dll files) for a cleaner look
procedure InitializeWizard;
begin
  WizardForm.FilenameLabel.Visible := False;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    if MsgBox('Do you also want to delete all offline songs and data saved by ShivaayMusic?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      // Remove the application data directory
      DelTree(ExpandConstant('{localappdata}\shivaaymusic'), True, True, True);
      DelTree(ExpandConstant('{userappdata}\shivaaymusic'), True, True, True);
      // Remove the installation directory completely if it still exists (emptied by uninstaller but folders might remain)
      DelTree(ExpandConstant('{app}'), True, True, True);
    end;
  end;
end;
