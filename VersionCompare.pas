unit VersionCompare;

interface

function NeedsUpdate(AOld, ANew: string): Boolean;

implementation

uses
  Classes, Types, SysUtils, StrUtils, Math;

function NeedsUpdate(AOld, ANew: string): Boolean;
var
  LUpdateOnEqual: Boolean;
  LOld, LNew: TStringDynArray;
  i, LOldV, LNewV: Integer;
begin
  Result := False;
  LOld := SplitString(AOld, '.');
  LNew := SplitString(ANew, '.');
  LUpdateOnEqual := Length(LNew) > Length(LOld);
  for i := 0 to Min(High(LOld), High(LNew)) do
  begin
    if TryStrToInt(LOld[i], LOldV) and TryStrToInt(LNew[i], LNewV) then
    begin
      Result := LNewV > LOldV;
      if Result or (LNewV < LOldV) then
      begin
        LUpdateOnEqual := False;
        Break;
      end;
    end
    else
    begin
      raise Exception.Create('Error in Versionstring');
    end;
  end;
  Result := Result or LUpdateOnEqual;
end;

end.
