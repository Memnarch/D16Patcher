unit AsyncPatcher;

interface

uses
  classes, Types, SysUtils, CommandoSettings, UpdateInfo, ExtActns;

type
  TProgressEvent = procedure(AMin, AMax, APosition: Integer) of object;
  TLogEvent = procedure(AMessage: string) of object;

  TAsyncPatcher = class(TThread)
  private
    FSettings: TCommandoSettings;
    FUpdates: TUpdateInfo;
    FSources: TStringList;
    FUpdateDir: string;
    FBaseDir: string;
    FOnLog: TLogEvent;
    FOnProgress: TProgressEvent;
    FMessage: string;
    FPatcherSource: string;
    FMin: Integer;
    FMax: Integer;
    FPosition: Integer;
    procedure DoLog(AMessage: string);
    procedure DoProgress(AMin, AMax, APosition: Integer);
    procedure CallLog();
    procedure CallProgress();
    procedure WaitIfDesired();
    procedure CollectRequiredPatches();
    procedure DownloadFiles();
    procedure ExtractFiles();
    procedure Cleanup();
    procedure HandleDownload
        (Sender: TDownLoadURL;
         Progress, ProgressMax: Cardinal;
         StatusCode: TURLDownloadStatus;
         StatusText: String; var Cancel: Boolean);
    function HasSelfPatch(): Boolean;
    procedure SelfPatch();
    procedure SelfInstall();
  protected
    procedure Execute(); override;
  public
    constructor Create(ASettings: TCommandoSettings; AUpdates: TUpdateInfo); reintroduce;
    destructor Destroy(); override;
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
    property OnLog: TLogEvent read FOnLog write FOnLog;
  end;

implementation

uses
  Forms, Windows, VersionCompare, IOUtils, AbBase, AbBrowse, AbZBrows, AbUnzper, PatcherVersion, Process;

{ TAsyncPatcher }

procedure TAsyncPatcher.CallLog;
begin
  if Assigned(FOnLog) then
  begin
    FOnLog(FMessage);
  end;
end;

procedure TAsyncPatcher.CallProgress;
begin
  if Assigned(FOnProgress) then
  begin
    FOnProgress(FMin, FMax, FPosition);
  end;
end;

procedure TAsyncPatcher.Cleanup;
var
  LFiles: TStringDynArray;
  LFile: string;
begin
  if DirectoryExists(FUpdateDir) then
  begin
    DoLog('Cleaning Updatefolder...');
    LFiles := TDirectory.GetFiles(FUpdateDir);
    for LFile in LFiles do
    begin
      DeleteFile(@LFile[1]);
    end;
    RemoveDirectory(@FUpdateDir[1]);
  end;
end;

procedure TAsyncPatcher.CollectRequiredPatches;
var
  i: Integer;
  LVersion: string;
begin
  DoLog('Required Updates:');
  for i := 0 to FUpdates.Components.Count - 1 do
  begin
    if SameText(FUpdates.Components[i], CPatcherName) then
    begin
      LVersion := CPatcherVersion;
    end
    else
    begin
      LVersion := FSettings.Versions[FUpdates.Components[i]];
    end;
    if NeedsUpdate(LVersion, FUpdates.Versions[i]) then
    begin
      DoLog(FUpdates.Components[i] + ' ' + FSettings.Versions[FUpdates.Components[i]] + ' -> ' + FUpdates.Versions[i]);
      if FSources.IndexOf(FUpdates.Sources[i]) < 0 then
      begin
        FSources.Add(FUpdates.Sources[i]);
        if SameText(FUpdates.Components[i], CPatcherName) then
        begin
          FPatcherSource := FUpdates.Sources[i];
        end;
      end;
    end;
  end;
  if FSources.Count = 0 then
  begin
    DoLog('<None>');
  end;
end;

constructor TAsyncPatcher.Create(ASettings: TCommandoSettings;
  AUpdates: TUpdateInfo);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FSources := TStringList.Create();
  FSettings := ASettings;
  FUpdates := AUpdates;
  FBaseDir := ExtractFilePath(ParamStr(0));
  FUpdateDir := FBaseDir + '\updates\';
end;

destructor TAsyncPatcher.Destroy;
begin
  FSources.Free;
  inherited;
end;

procedure TAsyncPatcher.DoLog(AMessage: string);
begin
  FMessage := AMessage;
  Synchronize(CallLog);
end;

procedure TAsyncPatcher.DoProgress(AMin, AMax, APosition: Integer);
begin
  FMin :=AMin;
  FMax := AMax;
  FPosition := APosition;
  Synchronize(CallProgress);
end;

procedure TAsyncPatcher.DownloadFiles;
var
  LDL: TDownLoadURL;
  i: Integer;
begin
  DoLog('Downloading files');
  ForceDirectories(FUpdateDir);
  LDL := TDownLoadURL.Create(nil);
  try
    LDL.OnDownloadProgress := HandleDownload;
    if FPatcherSource <> '' then
    begin
      DoLog('Downloading patcher...');
      LDL.URL := FPatcherSource;
      LDL.Filename := FUpdateDir + '\' + CPatcherName + '.zip';
      LDL.ExecuteTarget(nil);
    end
    else
    begin
      for i := 0 to FSources.Count - 1 do
      begin
        DoLog(IntToStr(i+1) + ' of ' + IntToStr(FSources.Count));
        LDL.URL := FSources[i];
        LDL.Filename := FUpdateDir + '\' + IntToStr(i) + '.zip';
        LDL.ExecuteTarget(nil);
      end;
    end;
  finally
    LDL.Free;
  end;
end;

procedure TAsyncPatcher.Execute;
begin
  inherited;
  WaitIfDesired();
  if FSettings.IsSelfInstall() then
  begin
    SelfInstall();
    Exit;
  end;
  Cleanup();
  CollectRequiredPatches();
  if FSources.Count > 0 then
  begin
    DownloadFiles();
    ExtractFiles();
  end;
  if HasSelfPatch() then
  begin
    SelfPatch();
    Exit;
  end;
  Cleanup();
  if FileExists(FBaseDir + '\D16IDE.exe') then
  begin
    RunProcess(FBaseDir + '\D16IDE.exe', '', False);
  end;
end;

procedure TAsyncPatcher.ExtractFiles;
var
  i: Integer;
  LZip: TAbUnZipper;
begin
  DoLog('Extracting...');
  LZip := TAbUnZipper.Create(nil);
  try
    if FPatcherSource <> '' then
    begin
      LZip.FileName := FUpdateDir + '\' + CPatcherName + '.zip';
      LZip.BaseDirectory := FUpdateDir;
      LZip.ExtractFiles('*');
    end
    else
    begin
      for i := 0 to FSources.Count - 1 do
      begin
        LZip.FileName := FUpdateDir + '\' + IntToStr(i) + '.zip';
        LZip.BaseDirectory := FBaseDir;
        LZip.ExtractFiles('*');
      end;
    end;
  finally
    LZip.Free;
  end;
end;

procedure TAsyncPatcher.HandleDownload(Sender: TDownLoadURL; Progress,
  ProgressMax: Cardinal; StatusCode: TURLDownloadStatus; StatusText: String;
  var Cancel: Boolean);
begin
  DoProgress(0, ProgressMax, Progress);
end;

function TAsyncPatcher.HasSelfPatch: Boolean;
begin
  Result := NeedsUpdate(CPatcherVersion, FUpdates.PatcherVersion);
end;

procedure TAsyncPatcher.SelfInstall;
var
  LTarget: string;
begin
  DoLog('Installing...');
  LTarget := FSettings.InstallPath + '\' + CPatcherName + '.exe';
  ForceDirectories(FSettings.InstallPath);
  if CopyFile(@Application.ExeName[1], @LTarget[1], False) then
  begin
    FSettings.InstallPath := '';
    FSettings.PID := GetCurrentProcessId();
    RunProcess(LTarget, FSettings.CommandoLine, False);
  end
  else
  begin
    raise Exception.Create('Failed to Copy patcher');
  end;
end;

procedure TAsyncPatcher.SelfPatch;
begin
  DoLog('Patching patcher...');
  FSettings.InstallPath := FBaseDir;
  FSettings.PID := GetCurrentProcessId();
  RunProcess(FUpdateDir + '\' + CPatcherName + '.exe', FSettings.CommandoLine, False);
end;

procedure TAsyncPatcher.WaitIfDesired;
var
  LHandle: THandle;
begin
  if FSettings.NeedToWait then
  begin
    DoLog('Waiting for host to exit...');
    LHandle := OpenProcess(PROCESS_ALL_ACCESS, False, FSettings.PID);
    if LHandle <> 0 then
    begin
      WaitForSingleObject(LHandle, INFINITE);
      CloseHandle(LHandle);
    end;
  end;
end;

end.
