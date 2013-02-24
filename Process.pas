unit Process;

interface

uses
  Classes, Types, SysUtils, Windows;

procedure RunProcess(AName, ACommand: string; ASameDir: Boolean);

implementation

procedure RunProcess(AName, ACommand: string; ASameDir: Boolean);
var
  LInfo: _STARTUPINFOW;
  LCurrentDir, LCommand: string;
  LProc: TProcessInformation;
begin
  ZeroMemory(@LInfo, SizeOf(LInfo));
  if ASameDir then
  begin
    LCurrentDir := ExtractFilePath(ParamStr(0));
  end
  else
  begin
    LCurrentDir := ExtractFilePath(AName);
  end;
  LCommand := AName + ' ' + ACommand;
  CreateProcess(nil, @LCommand[1], nil, nil, false, 0, nil, @LCurrentDir[1], LInfo, LProc);
end;

end.
