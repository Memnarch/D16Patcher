unit CommandoSettings;

interface

uses
  Classes, Types, SysUtils;

type
  TCommandoSettings = class
  private
    FComponents: TStringList;
    FUpdatefile: string;
    FInstallPath: string;
    FPID: Cardinal;
    function GetCommandoLine: string;
    function ReadPID(AIndex: Integer): Integer;
    function ReadFileName(AIndex: Integer): Integer;
    function ReadComponentVersion(AIndex: Integer): Integer;
    function ReadInstallPath(AIndex: Integer): Integer;
    function GetVersion(AName: string): string;
  public
    constructor Create();
    destructor Destroy(); override;
    procedure ReadFromCommandLine();
    function HasUpdateFile(): Boolean;
    function NeedToWait(): Boolean;
    function IsSelfInstall(): Boolean;
    property UpdateFile: string read FUpdatefile write FUpdateFile;
    property PID: Cardinal read FPID write FPID;
    property InstallPath: string read FInstallPath write FInstallPath;
    property Components: TStringList read FComponents;
    property Versions[AName: string]: string read GetVersion;
    property CommandoLine: string read GetCommandoLine;
  end;

implementation

uses
  StrUtils, Forms;

{ TCommandoSettings }

constructor TCommandoSettings.Create;
begin
  FComponents := TStringList.Create();
end;

destructor TCommandoSettings.Destroy;
begin
  FComponents.Free();
  inherited;
end;

function TCommandoSettings.GetCommandoLine: string;
var
  i: Integer;
begin
  Result := '';
  if IsSelfInstall then
  begin
    Result := Result + '-Install "' + FInstallPath + '" ';
  end;
  if NeedToWait then
  begin
    Result := Result + '-PID ' + IntToStr(FPID) + ' ';
  end;
  if HasUpdateFile then
  begin
    Result := Result + '-File "' + FUpdatefile + '" ';
  end;
  for i := 0 to FComponents.Count - 1 do
  begin
    Result := Result + '-Version ' + FComponents.Names[i] + ' ' + FComponents.ValueFromIndex[i] + ' ';
  end;
  Result := Trim(Result);
end;

function TCommandoSettings.GetVersion(AName: string): string;
begin
  Result := '0';
  if FComponents.IndexOfName(AName) > -1 then
  begin
    Result := FComponents.Values[AName];
  end;
end;

function TCommandoSettings.HasUpdateFile: Boolean;
begin
  Result := Trim(FUpdatefile) <> '';
end;

function TCommandoSettings.IsSelfInstall: Boolean;
begin
  Result := FInstallPath <> '';
end;

function TCommandoSettings.NeedToWait: Boolean;
begin
  Result := FPID > 0;
end;

function TCommandoSettings.ReadComponentVersion(AIndex: Integer): Integer;
begin
  Result := 3;
  FComponents.Add(ParamStr(AIndex + 1) + '=' + ParamStr(AIndex + 2));
end;

function TCommandoSettings.ReadFileName(AIndex: Integer): Integer;
begin
  Result := 2;
  FUpdatefile := ParamStr(AIndex + 1);
end;

procedure TCommandoSettings.ReadFromCommandLine;
var
  i: Integer;
begin
  if SameText(Application.ExeName, ParamStr(0)) then
  begin
    i := 1;
  end
  else
  begin
    i := 0;
  end;
  while(i < ParamCount) do
  begin
    case AnsiIndexText(ParamStr(i), ['-PID', '-File', '-Version', '-Install']) of
      0:
      begin
        i := i + ReadPID(i);
      end;

      1:
      begin
        i := i + ReadFileName(i);
      end;

      2:
      begin
        i := i + ReadComponentVersion(i);
      end;

      3:
      begin
        i := i + ReadInstallPath(i);
      end

      else
      begin
        raise Exception.Create('Invalid parameter ' + QuotedStr(ParamStr(i)) + ' at Index ' + IntToStr(i));
      end;
    end;
  end;
end;

function TCommandoSettings.ReadInstallPath(AIndex: Integer): Integer;
begin
  Result := 2;
  FInstallPath := ParamStr(AIndex + 1);
end;

function TCommandoSettings.ReadPID(AIndex: Integer): Integer;
begin
  Result := 2;
  FPID := StrToIntDef(ParamStr(AIndex + 1), 0);
end;

end.
