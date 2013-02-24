unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, pngimage, ExtCtrls, StdCtrls, CommandoSettings, UpdateInfo,
  ASyncPatcher;

type
  TPatcherForm = class(TForm)
    Progress: TProgressBar;
    Image1: TImage;
    Log: TMemo;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
    FSettings: TCommandoSettings;
    FUpdates: TUpdateInfo;
    FPatcher: TAsyncPatcher;
    FRunning: Boolean;
    procedure HandleTerminate(Sender: TObject);
    procedure HandleLog(AMessage: string);
    procedure HandleProgress(AMin, AMax, APosition: Integer);
  protected

  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;
  end;

var
  PatcherForm: TPatcherForm;

implementation

uses
  VersionCompare, PatcherVersion;

{$R *.dfm}

{ TPatcherForm }

constructor TPatcherForm.Create(AOwner: TComponent);
begin
  inherited;
  FUpdates := TUpdateInfo.Create();
  FSettings := TCommandoSettings.Create();
  FPatcher := TAsyncPatcher.Create(FSettings, FUpdates);
  FPatcher.OnProgress := HandleProgress;
  FPatcher.OnLog := HandleLog;
  FPatcher.OnTerminate := HandleTerminate;
  FSettings.ReadFromCommandLine();
  Log.Lines.Add('D16Patcher v. ' + CPatcherVersion);
  if FSettings.HasUpdateFile() then
  begin
    if not FSettings.IsSelfInstall then
    begin
      FUpdates.LoadFromFile(ExtractFilePath(Application.ExeName) + '\' + FSettings.UpdateFile);
    end;
    FRunning := True;
    FPatcher.Start();
  end
  else
  begin
    Log.Lines.Add('No updatefile specified');
  end;
end;

destructor TPatcherForm.Destroy;
begin
  FSettings.Free();
  FUpdates.Free;
  inherited;
end;

procedure TPatcherForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := True;
  if FRunning then
  begin
    if MessageDlg('Patcher is still performing an action. Do you really want to abort while patching?', mtWarning, mbYesNo, 0) = mrNo then
    begin
      CanClose := False;
    end;
  end;
end;

procedure TPatcherForm.HandleLog(AMessage: string);
begin
  Log.Lines.Add(AMessage);
end;

procedure TPatcherForm.HandleProgress(AMin, AMax, APosition: Integer);
begin
  //all the following +1 and backsetting forces the progressbar to update IMMEDIATELY instead of animating
  if APosition < AMax then
  begin
    Progress.Min := AMin;
    Progress.Max := AMax;
    Progress.Position := APosition + 1;
    Progress.Position := APosition;
  end
  else
  begin
    Progress.Min := AMin;
    Progress.Max := AMax + 1;
    Progress.Position := AMax + 1;
    Progress.Max := AMax;
  end;
end;

procedure TPatcherForm.HandleTerminate(Sender: TObject);
begin
  FRunning := False;
  Self.Close();
end;

end.
