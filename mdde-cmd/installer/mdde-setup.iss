; MDDE Windows 安装程序脚本
; 使用 Inno Setup 编译器生成安装包

[Setup]
; 应用基本信息
AppId={{B1A1F1E1-2A2B-4C4D-8E8F-1234567890AB}
AppName=MDDE (Multi Docker Development Environment)
AppVersion=0.1.0
AppVerName=MDDE 0.1.0
AppPublisher=MDDE Team
AppPublisherURL=https://github.com/your-username/mdde-cmd
AppSupportURL=https://github.com/your-username/mdde-cmd/issues
AppUpdatesURL=https://github.com/your-username/mdde-cmd/releases
AppCopyright=Copyright (C) 2024 MDDE Team
DefaultDirName={autopf}\MDDE
DefaultGroupName=MDDE
AllowNoIcons=yes
LicenseFile=..\LICENSE
InfoBeforeFile=installer-info.txt
InfoAfterFile=installer-post.txt
; 输出配置
OutputDir=output
OutputBaseFilename=MDDE-Setup-v{#SetupSetting("AppVersion")}-x64
;SetupIconFile=mdde-icon.ico
UninstallDisplayIcon={app}\mdde.exe
Compression=lzma
SolidCompression=yes
WizardStyle=modern
; 系统要求
MinVersion=10.0
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
;Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1
Name: "addtopath"; Description: "添加到系统 PATH 环境变量 (推荐)"; GroupDescription: "环境配置:"; Flags: checkedonce

[Files]
; 主程序文件
Source: "..\target\release\mdde.exe"; DestDir: "{app}"; Flags: ignoreversion
; 配置文件
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\PROJECT_SUMMARY.md"; DestDir: "{app}"; Flags: ignoreversion
; 示例文件
Source: "..\examples\*"; DestDir: "{app}\examples"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\MDDE"; Filename: "{app}\mdde.exe"
Name: "{group}\MDDE 帮助文档"; Filename: "{app}\README.md"
Name: "{group}\{cm:UninstallProgram,MDDE}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\MDDE"; Filename: "{app}\mdde.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\MDDE"; Filename: "{app}\mdde.exe"; Tasks: quicklaunchicon

[Registry]
; 添加到系统 PATH 环境变量
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}"; Check: NeedsAddPath('{app}'); Tasks: addtopath; Flags: uninsdeletevalue

[Run]
; 安装完成后运行
Filename: "{app}\mdde.exe"; Parameters: "version"; Description: "{cm:LaunchProgram,MDDE}"; Flags: nowait postinstall skipifsilent runhidden
Filename: "{app}\mdde.exe"; Parameters: "doctor"; Description: "运行系统检查"; Flags: nowait postinstall skipifsilent runhidden

[UninstallRun]
; 卸载前清理
Filename: "{app}\mdde.exe"; Parameters: "clean --all"; Flags: runhidden

[Code]
// 检查是否需要添加到 PATH
function NeedsAddPath(Param: string): boolean;
var
  OrigPath: string;
begin
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE,
    'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'Path', OrigPath)
  then begin
    Result := True;
    exit;
  end;
  // 检查路径是否已经存在
  Result := Pos(';' + UpperCase(Param) + ';', ';' + UpperCase(OrigPath) + ';') = 0;
end;

// 自定义页面：显示安装前信息
procedure InitializeWizard();
begin
  // 可以在这里添加自定义页面
end;

// 安装完成后的处理
procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    // 刷新环境变量
    if IsTaskSelected('addtopath') then
    begin
      // 通知系统环境变量已更改
      if not Exec('cmd.exe', '/c echo PATH updated', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      begin
        // 处理错误
      end;
    end;
  end;
end;

// 卸载时从 PATH 中移除
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  OrigPath, NewPath, AppDir: string;
  PathParts: TStringList;
  i: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    AppDir := ExpandConstant('{app}');
    if RegQueryStringValue(HKEY_LOCAL_MACHINE,
      'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
      'Path', OrigPath) then
    begin
      PathParts := TStringList.Create();
      try
        // 分割 PATH 字符串
        PathParts.Delimiter := ';';
        PathParts.DelimitedText := OrigPath;
        
        // 移除包含应用目录的路径
        for i := PathParts.Count - 1 downto 0 do
        begin
          if Pos(UpperCase(AppDir), UpperCase(PathParts[i])) > 0 then
            PathParts.Delete(i);
        end;
        
        // 重建 PATH 字符串
        NewPath := PathParts.DelimitedText;
        
        // 更新注册表
        RegWriteExpandStringValue(HKEY_LOCAL_MACHINE,
          'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
          'Path', NewPath);
          
      finally
        PathParts.Free();
      end;
    end;
  end;
end;

[Messages]
; 自定义消息
WelcomeLabel2=这将在您的计算机上安装 [name/ver]。%n%nMDDE 是一个强大的 Docker 多语言开发环境管理工具。%n%n建议在继续之前关闭所有其他应用程序。
ClickNext=单击"下一步"继续，或单击"取消"退出安装程序。
BeveledLabel=MDDE - 简化 Docker 开发环境管理

