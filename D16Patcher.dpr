program D16Patcher;



uses
  Forms,
  Main in 'Main.pas' {PatcherForm},
  CommandoSettings in 'CommandoSettings.pas',
  VersionCompare in 'VersionCompare.pas',
  UpdateInfo in 'UpdateInfo.pas',
  AsyncPatcher in 'AsyncPatcher.pas',
  PatcherVersion in 'PatcherVersion.pas',
  Process in 'Process.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPatcherForm, PatcherForm);
  Application.Run;
end.
