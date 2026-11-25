; Script de Instalador Inno Setup para Novos Começos
; Estúdios Paraíso dos Pássaros (Desenvolvedor: Luan Fernando Oliveira da Silva)

[Setup]
AppId={{D370A254-8B81-42C4-A60A-901EF36F174B}
AppName=Novos Começos
AppVersion=1.0.0
AppPublisher=Estúdios Paraíso dos Pássaros
AppPublisherURL=https://github.com/LuFer009-dev/Novos-Come-os
AppSupportURL=https://github.com/LuFer009-dev/Novos-Come-os/issues
AppUpdatesURL=https://github.com/LuFer009-dev/Novos-Come-os/releases
DefaultDirName={autopf}\Novos Comecos
DefaultGroupName=Novos Começos
AllowNoIcons=yes
OutputDir=.\installer_output
OutputBaseFilename=Instalador_Novos_Comecos_v1.0.0
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "windows\NovosComecos.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Novos Começos"; Filename: "{app}\NovosComecos.exe"
Name: "{group}\{cm:UninstallProgram,Novos Começos}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Novos Começos"; Filename: "{app}\NovosComecos.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\NovosComecos.exe"; Description: "{cm:LaunchProgram,Novos Começos}"; Flags: nowait postinstall skipifsilent
