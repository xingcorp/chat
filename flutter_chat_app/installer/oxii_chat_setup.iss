; Inno Setup Script for OXII Chat
; Download Inno Setup from: https://jrsoftware.org/isinfo.php
;
; UPDATE BEHAVIOR:
;   - AppId is FIXED → Inno Setup detects old version and upgrades in-place
;   - CloseApplications=yes → auto-closes running app before update
;   - Old files overwritten via "ignoreversion" flag
;   - User data (AppData) is preserved across updates
;   - Customer just runs the new .exe installer → done

; ── Read version from pubspec.yaml automatically ──
; If you want manual control, replace the ReadIni line with:
;   #define MyAppVersion "1.2.0"
#define MyAppVersion GetStringFileInfo("..\build\windows\x64\runner\Release\oxii_chat.exe", "ProductVersion")

#define MyAppName "OXII Chat"
#define MyAppPublisher "OXII"
#define MyAppURL "https://oxii.com"
#define MyAppExeName "oxii_chat.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
; ⚠️ CRITICAL: AppId must NEVER change — this is how Windows recognizes updates
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

; ── Output ──
OutputDir=..\build\installer
OutputBaseFilename=OxiiChat_Setup_v{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico

; ── Compression ──
Compression=lzma2/ultra64
SolidCompression=yes

; ── UI ──
WizardStyle=modern
PrivilegesRequired=lowest

; ── Architecture ──
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; ── UPDATE SUPPORT ──
; Allow installing over existing version (update in-place)
UsePreviousAppDir=yes
; Auto-close running OXII Chat before installing update
CloseApplications=yes
CloseApplicationsFilter=*.exe
; Restart app after update if it was running
RestartApplications=yes
; Show "update" text instead of "install" when upgrading
; Uninstall old version info is updated automatically

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main executable
Source: "{#BuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; All DLLs
Source: "{#BuildDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

; Data folder (Flutter assets) — exclude JIT kernel (debug-only, not needed in release)
Source: "{#BuildDir}\data\*"; DestDir: "{app}\data"; Excludes: "kernel_blob.bin"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Clean up any cache/temp files on uninstall (NOT user data)
Type: filesandordirs; Name: "{app}\cache"
Type: filesandordirs; Name: "{app}\logs"

[Code]
// Show different welcome message for updates vs fresh installs
function InitializeSetup(): Boolean;
begin
  Result := True;
end;

function IsUpgrade(): Boolean;
begin
  Result := RegKeyExists(HKEY_CURRENT_USER,
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}_is1');
end;

function UpdateReadyMemo(Space, NewLine, MemoUserInfoInfo, MemoDirInfo, MemoTypeInfo,
  MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
begin
  if IsUpgrade() then
    Result := 'OXII Chat will be updated to version {#MyAppVersion}.' + NewLine + NewLine +
              'Your chat history and settings will be preserved.' + NewLine + NewLine +
              MemoDirInfo
  else
    Result := MemoDirInfo + NewLine + MemoGroupInfo + NewLine + MemoTasksInfo;
end;
