unit UpdateInfo;

interface

uses
  Classes, Types, StrUtils, SysUtils;

type
  TUpdateInfo = class
  private
    FComponents: TStringlist;
    FVersions: TStringList;
    FSources: TStringlist;
    function GetPatcherVersion: string;

  public
    constructor Create();
    destructor Destroy(); override;
    procedure LoadFromFile(AFile: string);
    property Components: TStringlist read FComponents;
    property Versions: TStringList read FVersions;
    property Sources: TStringlist read FSources;
    property PatcherVersion: string read GetPatcherVersion;
  end;

implementation

uses
  IniFiles, PatcherVersion;

{ TUpdateInfo }

constructor TUpdateInfo.Create;
begin
  FComponents := TStringList.Create();
  FVersions := TStringList.Create();
  FSources := TStringList.Create();
end;

destructor TUpdateInfo.Destroy;
begin
  FComponents.Free;
  FVersions.Free;
  FSources.Free;
  inherited;
end;

function TUpdateInfo.GetPatcherVersion: string;
var
  LIndex: Integer;
begin
  Result := '0';
  LIndex := FComponents.IndexOf(CPatcherName);
  if LIndex > -1 then
  begin
    Result := FVersions[LIndex];
  end;
end;

procedure TUpdateInfo.LoadFromFile(AFile: string);
var
  LIni: TIniFile;
  LSection: string;
begin
  if not FileExists(AFile) then
  begin
    raise Exception.Create('Update file ' + QuotedStr(AFile) + ' does not exists!');
  end;
  LIni := TIniFile.Create(AFile);
  try
    LIni.ReadSections(FComponents);
    for LSection in FComponents do
    begin
      FVersions.Add(LIni.ReadString(LSection, 'Version', '0'));
      FSources.Add(LIni.ReadString(LSection, 'Source', ''));
    end;
  finally
    LIni.Free;
  end;
end;

end.
