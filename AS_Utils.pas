unit AS_Utils;

{
    Unit AS_Utils (for use with Absynth)
    Copyright (c) 2017-2018 Coenrad Fourie

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
}

interface

uses
{$IFDEF Unix}
  Process,
{$ENDIF Unix}
  SysUtils, Math, AS_Globals;

procedure EchoLn(eText : string);
procedure WriteWarningsAndErrors;
procedure CleanMemory;
procedure CloseWithHaltCode(EText : string; HCode : integer);
procedure WordToBytes(wtbWord : word; var wtbByteH, wtbByteL : byte);
procedure Chop4ByteInt(cint : integer; var b1, b2, b3, b4 : byte);
function CheckIfReal(TestStr : string) : boolean;
function CheckIfInteger(TestStr : string) : boolean;
function ClosestGridPoint(cgReal, cgGridSize : double) : integer;
procedure AddWarningString(awStr : str79);
procedure AddErrorString(awStr : str79);
function VariableIsDefined(varName : string) : Boolean;
function ReadVariableValue(rv : string) : Double;
function ReadDeviceType(rdName : string) : TDeviceTypes;
function GetMinSpace(gmLayerFrom, gmLayerTo : integer) : double;
function GetSurround(gsLayerFrom, gsLayerTo : integer) : double;
function GetDeviceParameter(gdParamName : string; gdDevParams : TDevParamArray) : double;

implementation

{ --------------------------------- EchoLn ----------------------------------- }
procedure EchoLn(eText : string);
// Write text to both the screen and an output file
begin
  WriteLn(eText);
  if TTextRec(outFile).Mode <> fmClosed then
    WriteLn(outFile,eText);
end; // EchoLn
{ ------------------------- WriteWarningsAndErrors --------------------------- }
procedure WriteWarningsAndErrors;

var
  ww1 : integer;
begin
  if Length(warningStrings) > 0 then
  begin
    EchoLn(''); WriteLn('WARNINGS:');
    for ww1 := 0 to High(warningStrings) do
      EchoLn(warningStrings[ww1]);
  end;
  if Length(errorStrings) > 0 then
  begin
    EchoLn(''); WriteLn('ERRORS:');
    for ww1 := 0 to High(errorStrings) do
      EchoLn(errorStrings[ww1]);
  end;
end; // WriteWarningsAndErrors
{ ------------------------------ CleanMemory --------------------------------- }
procedure CleanMemory;

begin
  // Deallocate dynamic arrays and close files
  warningStrings := nil;
  errorStrings := nil;
  paramVariable := nil;
  devJJ := nil;
end;
{ --------------------------- CloseWithHaltCode ------------------------------ }
procedure CloseWithHaltCode(EText : string; HCode : integer);
// Writes text to both the screen and an output file, then closes file and halts
begin
  EchoLn('('+IntToStr(HCode)+') '+EText);
  WriteWarningsAndErrors;
  CloseFile(outFile);
  CleanMemory;
  Halt(HCode);
end; // CloseWithHaltCode
{ ------------------------------ WordToBytes --------------------------------- }
procedure WordToBytes(wtbWord : word; var wtbByteH, wtbByteL : byte);
begin
  wtbByteH := wtbWord div 256;
  wtbByteL := wtbWord mod 256;
end;  // WordToBytes
{ ------------------------------ Chop4ByteInt -------------------------------- }
procedure Chop4ByteInt(cint : integer; var b1, b2, b3, b4 : byte);

var
  dummy : integer;
begin
  dummy := cint and $FF;
  b4 := dummy;
  cint := cint shr 8;
  dummy := cint and $FF;
  b3 := dummy;
  cint := cint shr 8;
  dummy := cint and $FF;
  b2 := dummy;
  cint := cint shr 8;
  dummy := cint and $FF;
  b1 := dummy;
end; // Chop4ByteInt
{ ------------------------------ CheckIfReal --------------------------------- }
function CheckIfReal(TestStr : string) : boolean;
var
  c1 : integer;
  cb, cexpfound, cpointfound, cesignfound, cefound : boolean;
begin
  cb := true;
  cexpfound := false;
  cpointfound := false;
  cefound := false;
  while copy(TestStr,1,1) = ' ' do
    delete(TestStr,1,1);                // Strip leading spaces
  if TestStr = '' then                  // Cannot strip an empty string
  begin
    CheckIfReal := False; Exit;
  end;
  while copy(TestStr,length(TestStr),1) = ' ' do
    delete(TestStr,length(TestStr),1);  // strip trailing spaces
  if length(TestStr) = 1 then
    if not (ord(TestStr[1]) in [48..57]) then cb := false;
  if not ( (ord(TestStr[1]) in [48..57]) or (TestStr[1] in ['-','+','.']) ) then
    cb := false;
  if  copy(TestStr,1,1) = '.' then
    cpointfound := true;
  for c1 := 2 to length(TestStr) do
  begin
    if (cpointfound or cefound) and (copy(TestStr,c1,1) = '.') then
      cb := false;
    if copy(TestStr,c1,1) = '.' then cpointfound := true;
    if (not cefound) and (TestStr[c1] in ['-','+']) then
      cb := false;
    if cefound and (ord(TestStr[c1]) in [48..57]) then
      cexpfound := true;
    if not ( (ord(TestStr[c1]) in [48..57]) or (TestStr[c1] in ['-','+','.','e','E']) ) then cb := false;
    if cefound and (TestStr[c1] in ['e','E']) then
      cb := false;
    if TestStr[c1] in ['e','E'] then
      cefound := true;
    if (cefound and cexpfound) and (TestStr[c1] in ['-','+']) then
      cb := false;
    if (cefound and (not cexpfound)) and (TestStr[c1] in ['-','+']) then
      cesignfound := true;
  end;
  CheckIfReal := cb;
end; // CheckIfReal
{ ----------------------------- CheckIfInteger ------------------------------- }
function CheckIfInteger(TestStr : string) : boolean;

var
  c1 : integer;
  cb : boolean;
begin
  cb := true;
  if length(TestStr) = 1 then
    if not (ord(TestStr[1]) in [48..57]) then cb := false;
  if not ((TestStr[1] in ['+','-']) or (ord(TestStr[1]) in [48..57])) then
    cb := false;
  for c1 := 2 to length(TestStr) do
    if not (ord(TestStr[c1]) in [48..57]) then  // check if ordinal values of every character is in range 48 (0) to 57 (9)
      cb := false;
  CheckIfInteger := cb;
end; // CheckIfInteger
{ ---------------------------- ClosestGridPoint ------------------------------ }
function ClosestGridPoint(cgReal, cgGridSize : double) : integer;

var
  cg1, cgResult : integer;
  cg2, cgSign : double;
begin
  cgResult := 0;
  cgSign := 1.0;
  if cgReal < 0 then
    cgSign := -1.0;
  cg2 := RoundTo(cgReal/cgGridSize,0);
  if abs(cgReal - cgGridSize*cg2) < (cgGridSize/2) then
    cgResult := Round(cgGridSize*cg2)
  else
    cgResult := Round(cgGridSize*(cg2+cgSign));
  ClosestGridPoint := cgResult;
end; // ClosestGridPoint

{ ---------------------------- AddWarningString ------------------------------ }
procedure AddWarningString(awStr : str79);

begin
  SetLength(warningStrings,Length(warningStrings)+1);
  warningStrings[High(warningStrings)] := awStr;
end; // AddWarningString;
{ ----------------------------- AddErrorString ------------------------------- }
procedure AddErrorString(awStr : str79);

begin
  SetLength(errorStrings,Length(errorStrings)+1);
  errorStrings[High(errorStrings)] := awStr;
end; // AddErrorString;
{ ---------------------------- VariableIsDefined ----------------------------- }
function VariableIsDefined(varName : string) : Boolean;
var
  v1 : Integer;
  VRes : Boolean;
begin
  VRes := False;
  if Length(paramVariable) > 0 then
  begin
    for v1 := 0 to High(paramVariable) do
      if paramVariable[v1].name = varName then
        VRes := True;
  end;
  VariableIsDefined := VRes;
end; // VariableIsDefined
{ ---------------------------- ReadVariableValue ----------------------------- }
function ReadVariableValue(rv : string) : Double;

var
  rv1 : Integer;
  rvRet : Double;
begin
  rvRet := 0;
  if rv[1] = '%' then
  begin
    for rv1 := 0 to High(paramVariable) do
      if paramVariable[rv1].name = Copy(rv,2,Length(rv)-1) then  // strip out the '%'
        rvRet := paramVariable[rv1].value;
  end
  else
    if CheckIfReal(rv) then
      rvRet := StrToFloat(rv)
    else
      CloseWithHaltCode('Cannot parse '+rv+'. Did you forget "%"?.', 2);
  ReadVariableValue := rvRet;
end; // ReadVariableValue
{ ----------------------------- ReadDeviceType ------------------------------- }
function ReadDeviceType(rdName : string) : TDeviceTypes;

var
  rd1 : integer;
  rdType : TDeviceTypes;
begin
  rdType := DEVICEUNDEF;
  for rd1 := 0 to High(devJJ) do
    if devJJ[rd1].Name = rdName then
      rdType := DEVICEJJ;
// Should test here for other devices when these are added
  ReadDeviceType := rdType;
end; // ReadDeviceType
{ ------------------------------ GetMinSpace --------------------------------- }
function GetMinSpace(gmLayerFrom, gmLayerTo : integer) : double;

var
  gmMinSpace : double;
  gm1 : integer;
begin
  gmMinSpace := 0;  // Default value if no minspace declared - beware of floating point division with this default...
  if (gmLayerFrom > -1) and (gmLayerTo > -1) then
    if Length(layer[gmLayerFrom].MinSpace) > 0 then
      for gm1 := 0 to High(layer[gmLayerFrom].MinSpace) do
        if layer[gmLayerFrom].MinSpace[gm1].Layer = gmLayerTo then
          gmMinSpace := layer[gmLayerFrom].MinSpace[gm1].Value;
  GetMinSpace := gmMinSpace;
end;
{ ------------------------------ GetSurround --------------------------------- }
function GetSurRound(gsLayerFrom, gsLayerTo : integer) : double;

var
  gsSurround : double;
  gs1 : integer;
begin
  gsSurround := 0;  // Default value if no surround declared - beware of floating point division with this default...
  if (gsLayerFrom > -1) and (gsLayerTo > -1) then
    if Length(layer[gsLayerFrom].Surround) > 0 then
      for gs1 := 0 to High(layer[gsLayerFrom].Surround) do
        if layer[gsLayerFrom].Surround[gs1].Layer = gsLayerTo then
          gsSurround := layer[gsLayerFrom].Surround[gs1].Value;
  GetSurround := gsSurround;
end;
{ --------------------------- GetDeviceParameter ----------------------------- }
function GetDeviceParameter(gdParamName : string; gdDevParams : TDevParamArray) : double;

var
  gdValue : double;
  gd1 : integer;
begin
  gdValue := 1E-18;  // Default value if no surround declared - beware of floating point division with this default...
  if Length(gdDevParams) > 0 then
    for gd1 := 0 to High(gdDevParams) do
      if gdDevParams[gd1].Name = gdParamName then
        gdValue := gdDevParams[gd1].Value;
  GetDeviceParameter := gdValue;
end;

end.
