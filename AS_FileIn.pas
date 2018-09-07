unit AS_FileIn;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{
    Unit AS_FileIn (for use with Absynth)
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
  SysUtils, Math, AS_Globals, AS_Math, AS_Strings, AS_Synth, AS_Utils;

procedure Swop(var i1, i2 : integer);
procedure LnTABreplace(var lnText : string);
procedure ReadCleanLn(var rcFile : TextFile; var cleanLine : string);
procedure ReadAbsVariable(var raFile : TextFile; raFileName : string);
procedure ReadAbsPoly(var raFile : TextFile; raFileName : string);
procedure ReadAbsDevice(var raFile : TextFile; raFileName : string);
procedure ReadAbsJJ(var raFile : TextFile; raFileName : string);
procedure ReadLayerRule(var rlFile : TextFile; rlFileName : string; var rlLayerRule : TLayerRuleArray);
procedure ReadProcessFile(rpFileName : string);
procedure ReadAbsScript(raFileName : string);


implementation

{ ---------------------------------- Swop ------------------------------------ }
procedure Swop(var i1, i2 : integer);
// Swops twop integers
var
  ii : integer;
begin
  ii := i1;
  i1 := i2;
  i2 := ii;
end; // Swop
{ ------------------------------ LnTABreplace -------------------------------- }
procedure LnTABreplace(var lnText : string);
// Replaces TAB characters in text line with spaces, and makes lowercase
var
  lnFNtext : string;
begin
  if lnText <> '' then lnFNtext := StringReplace(lnText,#9,' ',[rfReplaceAll])
    else lnFNtext := ' ';
  lnText := lowercase(lnFNtext);
end; // ReadLnTABreplace
{ ------------------------------- ReadCleanLn -------------------------------- }
procedure ReadCleanLn(var rcFile : TextFile; var cleanLine : string);
// Strip out comments and remove empty lines.
// Also convert TAB to space, and strip start and end whitespace.
var
  rcStr : string;
  foundLine : boolean;
begin
  repeat
    foundLine := true;
    ReadLn(rcFile, rcStr);
    if rcStr = '' then
      foundLine := false
    else
    begin
      if (rcStr[1] = '*') or (pos('//',rcStr) = 1) then
        foundLine := false;    // Line is only a comment
      if foundLine then
      begin
        if pos('//',rcStr) > 1 then
        begin
          rcStr := copy(rcStr,1,pos('//',rcStr)-1);
          rcStr := lowercase(StringReplace(rcStr,#9,' ',[rfReplaceAll]));
        end;
        rcStr := StripSpaces(rcStr);
        if rcStr = '' then
          foundLine := false;
      end;
    end;
  until foundLine or eof(rcFile);
  cleanLine := rcStr;
end; // ReadCleanLn
{ ----------------------------- ReadAbsVariable ------------------------------ }
procedure ReadAbsVariable(var raFile : TextFile; raFileName : string);

var
  raTextInner, raTempName, raTempValue, raPar : string;
begin
  raTempName := '';  raTempValue := '';
  repeat
    ReadCleanLn(raFile, raTextInner);
    raPar := ReadStrFromMany(1, raTextInner, ' ');
    if raPar = 'name' then raTempName := ReadStrFromText(raTextInner);
    if raPar = 'value' then raTempValue := ReadStrFromText(raTextInner);
  until raPar = '$end';   // of Variable
  if (raTempName <> '') and (raTempName <> ' ') then
    if not VariableIsDefined(raTempName) then
    begin
      SetLength(paramVariable,Length(paramVariable)+1);
      paramVariable[High(paramVariable)].name := raTempName;
      paramVariable[High(paramVariable)].value := EvaluateExpression(raTempValue,1.0);
    end
    else
      AddWarningString('Variable '+raTempName+' defined more than once. Only first instance kept.');
end;  // ReadAbsVariable
{ ------------------------------- ReadAbsPoly -------------------------------- }
procedure ReadAbsPoly(var raFile : TextFile; raFileName : string);

var
  raTextInner, raPar : string;
begin
  SetLength(polys,Length(polys)+1);
  repeat
    ReadCleanLn(raFile, raTextInner);
    raPar := ReadStrFromMany(1, raTextInner, ' ');
    if raPar = 'layer' then polys[High(polys)].Layer := ReadIntFromText(raTextInner,0,'Error reading polygon layer from '+raFileName+'.');
    if raPar = 'xy' then
    begin
      SetLength(polys[High(polys)].Coords,0);
      repeat
        ReadCleanLn(raFile, raTextInner);
        if not ((pos('{',raTextInner) > 0) or (pos('}',raTextInner) > 0)) then
        begin
          SetLength(polys[High(polys)].Coords,Length(polys[High(polys)].Coords)+1);
          polys[High(polys)].Coords[High(polys[High(polys)].Coords)].x := Round(drawScale*EvaluateExpression(ReadStrFromMany(1,raTextInner,','),1.0));
          polys[High(polys)].Coords[High(polys[High(polys)].Coords)].y := Round(drawScale*EvaluateExpression(ReadStrFromMany(2,raTextInner,','),1.0));
        end;
      until pos('}',raTextInner) > 0;
    end;
  until raPar = '$end';   // of Polygon
end;  // ReadAbsPoly
{ ------------------------------ ReadAbsDevice ------------------------------- }
procedure ReadAbsDevice(var raFile : TextFile; raFileName : string);

var
  raTextInner, raTempDef, raPar, raDevPar : string;
  raX, raY : double;
  raTempRotate : double;
  raParams : TDevParamArray;
begin
  raTempDef := '';
  raTempRotate := 0;
  raX := 0;
  raY := 0;
  SetLength(raParams,0);
  repeat
    ReadCleanLn(raFile, raTextInner);
    raPar := ReadStrFromMany(1, raTextInner, ' ');
    if raPar = 'definition' then raTempDef := ReadStrFromText(raTextInner);
    if raPar = 'rotate' then raTempRotate := EvaluateExpression(ReadStrFromText(raTextInner),1.0);
    if raPar = 'xy' then
    begin
      repeat
        ReadCleanLn(raFile, raTextInner);
        if not ((pos('{',raTextInner) > 0) or (pos('}',raTextInner) > 0)) then
        begin
          raX := EvaluateExpression(ReadStrFromMany(1,raTextInner,','),1.0);
          raY := EvaluateExpression(ReadStrFromMany(2,raTextInner,','),1.0);
        end;
      until pos('}',raTextInner) > 0;
    end;
    if raPar = 'parameters' then
    begin
      repeat
        ReadCleanLn(raFile, raTextInner);
        raDevPar := ReadStrFromMany(1, raTextInner, ' ');
        if not ((pos('{',raTextInner) > 0) or (pos('}',raTextInner) > 0)) then
        begin
          SetLength(raParams,Length(raParams)+1);
          raParams[High(raParams)].Name := raDevPar;
          raParams[High(raParams)].Value := EvaluateExpression(ReadStrFromText(raTextInner),1.0);
        end;
      until pos('}',raTextInner) > 0;
    end;
  until raPar = '$end';   // of Polygon
  if ReadDeviceType(raTempDef) = DEVICEJJ then
    SynthJJ(raTempDef, raX, raY, raTempRotate, raParams);

end;  // ReadAbsDevice
{ ---------------------------- ReadAbsJJObject ------------------------------- }
procedure ReadAbsJJObject(var raFile : TextFile; raFileName : string; var jjObj : TDevObject);

var
  raTextInner, raObjPar, raTemp : string;
begin
  raTemp := '';
  jjObj.Layer := -1;
  jjObj.CirclePoints := 10;
  jjObj.Shape := SHAPECIRCLE;
  jjObj.Offset := 0;
  repeat
    ReadCleanLn(raFile, raTextInner);
    if not ((pos('{',raTextInner) > 0) or (pos('}',raTextInner) > 0)) then
    begin
      raObjPar := ReadStrFromMany(1, raTextInner, ' ');
      if raObjPar = 'layer' then jjObj.Layer := ReadIntFromText(raTextInner,-1,'Error reading object layer number in '+raFileName+'.');
      if raObjPar = 'shape' then
      begin
        raTemp := ReadStrFromText(raTextInner);
        if raTemp = 'circle' then jjObj.Shape := SHAPECIRCLE;
        if raTemp = 'mcircle' then jjObj.Shape := SHAPEMCIRCLE;
      end;
      if raObjPar = 'offset' then jjObj.Offset := ReadRealFromText(raTextInner,0,'Error reading object offset from '+raFileName+'.');
      if raObjPar = 'circlepoints' then jjObj.CirclePoints := ReadIntFromText(raTextInner,10,'Error reading object circle points in '+raFileName+'.');
    end;
  until pos('}',raTextInner) > 0;
end;  // ReadAbsJJObject
{ -------------------------------- ReadAbsJJ --------------------------------- }
procedure ReadAbsJJ(var raFile : TextFile; raFileName : string);

var
  raTextInner, raPar, raObjPar, raTemp : string;
begin
  raTemp := '';
  SetLength(devJJ,Length(devJJ)+1);
  with devJJ[High(devJJ)] do
  begin
    Name := '';
    Base.Layer := -1;
    Counter.Layer := -1;
    JJ.Layer := -1;
    RsLayer := -1;
    RsViaLayer := -1;
    JJViaLayer := -1;
    CounterBaseViaLayer := -1;
    LowerGndLayer := -1;
    LowerGndViaLayer := -1;
    IsGrounded := false;
    Base.CirclePoints := 10;
    Counter.CirclePoints := 10;
    JJ.CirclePoints := 10;
    Base.Shape := SHAPECIRCLE;
    Counter.Shape := SHAPECIRCLE;
    JJ.Shape := SHAPECIRCLE;
    SetLength(Objects,0);
    SetLength(Parameters,0);
  end;
  repeat
    ReadCleanLn(raFile, raTextInner);
    raPar := ReadStrFromMany(1, raTextInner, ' ');
    if raPar = 'name' then devJJ[High(devJJ)].Name := ReadStrFromText(raTextInner);
    if raPar = 'parameters' then
    begin
      repeat
        ReadCleanLn(raFile, raTextInner);
        if not ((pos('{',raTextInner) > 0) or (pos('}',raTextInner) > 0)) then
        begin
          SetLength(devJJ[High(devJJ)].Parameters,Length(devJJ[High(devJJ)].Parameters)+1);
          devJJ[High(devJJ)].Parameters[High(devJJ[High(devJJ)].Parameters)].Name := raTextInner;
          devJJ[High(devJJ)].Parameters[High(devJJ[High(devJJ)].Parameters)].Value := 0;
        end;
      until pos('}',raTextInner) > 0;
    end;
    if raPar = 'base' then ReadAbsJJObject(raFile, raFileName, devJJ[High(devJJ)].Base);
    if raPar = 'counter' then ReadAbsJJObject(raFile, raFileName, devJJ[High(devJJ)].Counter);
    if raPar = 'jj' then ReadAbsJJObject(raFile, raFileName, devJJ[High(devJJ)].JJ);
    if raPar = 'object' then
    begin
      SetLength(devJJ[High(devJJ)].Objects,Length(devJJ[High(devJJ)].Objects)+1);
      ReadAbsJJObject(raFile, raFileName,devJJ[High(devJJ)].Objects[High(devJJ[High(devJJ)].Objects)]);
    end;
    if raPar = 'rslayer' then devJJ[High(devJJ)].RsLayer := ReadIntFromText(raTextInner,-1,'Error reading RsLayer in '+raFileName+'.');
    if raPar = 'rsvialayer' then devJJ[High(devJJ)].RsViaLayer := ReadIntFromText(raTextInner,-1,'Error reading RsViaLayer in '+raFileName+'.');
    if raPar = 'counterbasevialayer' then devJJ[High(devJJ)].CounterBaseViaLayer := ReadIntFromText(raTextInner,-1,'Error reading CounterBaseViaLayer in '+raFileName+'.');
    if raPar = 'jjvialayer' then devJJ[High(devJJ)].JJViaLayer := ReadIntFromText(raTextInner,-1,'Error reading JJViaLayer in '+raFileName+'.');
    if raPar = 'lowergroundlayer' then devJJ[High(devJJ)].LowerGndLayer := ReadIntFromText(raTextInner,-1,'Error reading LowerGroundLayer in '+raFileName+'.');
    if raPar = 'lowergroundvialayer' then devJJ[High(devJJ)].LowerGndViaLayer := ReadIntFromText(raTextInner,-1,'Error reading LowerGroundViaLayer in '+raFileName+'.');
    if raPar = 'isgrounded' then
      if ReadStrFromText(raTextInner) = 'true' then devJJ[High(devJJ)].IsGrounded := true;
  until raPar = '$end';
end;  // ReadAbsJJ
{ ------------------------------ ReadLayerRule ------------------------------- }
procedure ReadLayerRule(var rlFile : TextFile; rlFileName : string; var rlLayerRule : TLayerRuleArray);

var
  rlText, rlPar : string;
  rlInt : integer;
begin
  repeat
    ReadCleanLn(rlFile, rlText);
    if not ((pos('{',rlText) > 0) or (pos('}',rlText) > 0)) then
      if pos('=',rlText) > 0 then
      begin
        SetLength(rlLayerRule,Length(rlLayerRule)+1);
        if CheckIfInteger(StripSpaces(ReadStrFromMany(1,rlText,'='))) then
          rlInt := StrToInt(StripSpaces(ReadStrFromMany(1,rlText,'=')))
        else
        begin
          rlInt := -1;
          EchoLn('Error reading Layer from '+rlFileName+'.');
        end;
        rlLayerRule[High(rlLayerRule)].Layer := rlInt;
        rlLayerRule[High(rlLayerRule)].Value := ReadRealFromText(rlText,0,'Error reading Value from '+rlFileName+'.');
      end;
  until pos('}',rlText) > 0;
end; // ReadLayerRule
{ ----------------------------- ReadProcessFile ------------------------------ }
procedure ReadProcessFile(rpFileName : string);

var
  rpFile : textFile;
  rpText, rpTextInner, rpStr, rpPar, rpLayerName, rpLayerType : string;
  rpLayerNum : integer;
  rpLayerJc, rpLayerDc, rpLayerB, rpLayerGridSize, rpLayerSheetRes, rpLayerMinSize, rpLayerMaxSize, rpLayerMaxWidth : double;
  rpLayerRuleMinSpace, rpLayerRuleSurround : TLayerRuleArray;
begin
  AssignFile(rpFile,rpFileName);
  {$I-}
  Reset(rpFile);
  {$I+}
  if ioResult <> 0 then
    CloseWithHaltCode('Cannot read file '+rpFileName,1);
  // Make sure to read the parameter block first - if defined, parameters override all other defaults
  repeat
    ReadCleanLn(rpFile, rpText);
    rpStr := ReadStrFromMany(1,rpText,' ');
    if rpStr = '$parameters' then
    begin
      repeat
        ReadCleanLn(rpFile, rpTextInner);
        rpPar := ReadStrFromMany(1, rpTextInner, ' ');
        if rpPar = 'units' then unitSize := ReadRealFromText(rpTextInner,UNITSIZEINMETRES,'Error reading unit size from '+rpFileName+'.');
      until rpPar = '$end';   // of Parameters
    end;
  until (rpStr = '$eof') or (eof(rpFile));
  Reset(rpFile);
  repeat
    ReadCleanLn(rpFile, rpText);
    rpStr := ReadStrFromMany(1,rpText,' ');
    if rpStr = '$layer' then
    begin     // make provision for "Number" not always being declared first. Grab all variables -> send to laag[ialaag] at end
      rpLayerNum := -1;
      rpLayerName := '';
      rpLayerJc := DEFAULTPROCESSJC;
      rpLayerDc := 0;
      rpLayerB  := 0;
      rpLayerGridSize := 0.025;
      rpLayerSheetRes := 1.0;
      rpLayerMaxSize := -1;
      rpLayerMinSize := 1.0;
      rpLayerMaxWidth := -1;
      SetLength(rpLayerRuleMinSpace,0);
      SetLength(rpLayerRuleSurround,0);
      rpLayerType := '';
      repeat
        ReadCleanLn(rpFile, rpTextInner);
        rpPar := ReadStrFromMany(1,rpTextInner,' ');
        if rpPar = 'number' then rpLayerNum := ReadIntFromText(rpTextInner,-1,'Error reading layer number in '+rpFileName+'.');
        if rpPar = 'name' then rpLayerName := ReadStrFromText(rpTextInner);
        if rpPar = 'jc' then rpLayerJc := ReadRealFromText(rpTextInner,DEFAULTPROCESSJC,'Error reading Jc from '+rpFileName+'.');
        if rpPar = 'dc' then rpLayerDc := ReadRealFromText(rpTextInner,0,'Error reading dc from '+rpFileName+'.');
        if rpPar = 'b' then rpLayerB := ReadRealFromText(rpTextInner,0,'Error reading b from '+rpFileName+'.');
        if rpPar = 'gridsize' then rpLayerGridSize := ReadRealFromText(rpTextInner,0,'Error reading GridSize from '+rpFileName+'.');
        if rpPar = 'sheetresistance' then rpLayerSheetRes := ReadRealFromText(rpTextInner,0,'Error reading SheetResistance from '+rpFileName+'.');
        if rpPar = 'minsize' then rpLayerMinSize := ReadRealFromText(rpTextInner,0,'Error reading MinSize from '+rpFileName+'.');
        if rpPar = 'maxsize' then rpLayerMaxSize := ReadRealFromText(rpTextInner,-1,'Error reading MaxSize from '+rpFileName+'.');
        if rpPar = 'maxwidth' then rpLayerMaxWidth := ReadRealFromText(rpTextInner,-1,'Error reading MaxWidth from '+rpFileName+'.');
        if rpPar = 'type' then rpLayerType := ReadStrFromText(rpTextInner);
        if rpPar = 'minspace' then ReadLayerRule(rpFile, rpFileName, rpLayerRuleMinSpace);
        if rpPar = 'surround' then ReadLayerRule(rpFile, rpFileName, rpLayerRuleSurround);
      until ((rpPar = '$end') or eof(rpFile));
      if rpLayerNum > -1 then
      begin
        if rpLayerName = '' then
          CloseWithHaltCode('Layer number '+IntToStr(rpLayerNum)+': name not defined in '+rpFileName,11);
        with layer[rpLayerNum] do
        begin
          Number := rpLayerNum;
          Name := rpLayerName;
          Jc := rpLayerJc;
          Dc := rpLayerDc;
          b := rpLayerB;
          GridSize := rpLayerGridSize;
          SheetResistance := rpLayerSheetRes;
          MinSize := rpLayerMinSize;
          MaxSize := rpLayerMaxSize;
          MaxWidth := rpLayerMaxWidth;
          MinSpace := rpLayerRuleMinSpace;
          Surround := rpLayerRuleSurround;
          if rpLayerType = 'jj' then Typ := JJ;
          if rpLayerType = 'res' then Typ := RES;
          if rpLayerType = 'sc' then Typ := SC;
          if rpLayerType = 'via' then Typ := VIA;
         end;
      end
      else
        if rpLayerName <> '' then
          AddWarningString('Layer "'+rpLayerName+'": number not defined in '+rpFileName+'. Ignored.');
    end;   // of Layer block
  until (rpStr = '$eof') or (eof(rpFile));
  CloseFile(rpFile);
end; // ReadProcessFile
{ ------------------------------ ReadAbsScript ------------------------------- }
procedure ReadAbsScript(raFileName : string);
// Read the .ABS script file
var
  raFile, raProcFile : TextFile;
  raText, raTextInner, raStr, raTempName, raTempValue, raPar : string;

begin
  AssignFile(raFile,raFileName);
  {$I-}
  Reset(raFile);
  {$I+}
  if ioResult <> 0 then
    CloseWithHaltCode('Cannot read file '+raFileName,1);
  // Make sure to read the parameter block first - if defined, parameters override all other defaults
  repeat
    ReadCleanLn(raFile, raText);
    raStr := ReadStrFromMany(1,raText,' ');
    if raStr = '$parameters' then
    begin
      repeat
        ReadCleanLn(raFile, raTextInner);
        raPar := ReadStrFromMany(1, raTextInner, ' ');
        if raPar = 'units' then unitSize := ReadRealFromText(raTextInner,UNITSIZEINMETRES,'Error reading unit size from '+raFileName+'.');
        if raPar = 'processfile' then processFileName := ReadStrFromText(raTextInner);
        if raPar = 'gdsoutfile' then gdsOutFileName := ReadStrFromText(raTextInner);
        if raPar = 'structname' then structName := ReadStrFromText(raTextInner);
        if raPar = 'include' then ReadAbsScript(ReadStrFromText(raTextinner));
      until raPar = '$end';   // of Parameters
    end;
  until (raStr = '$eof') or (eof(raFile));
  // Now read the process file
  if processFileName = '' then
    CloseWithHaltCode('No process file selected.', 10);
  ReadProcessFile(processFileName);

  Reset(raFile);  // Start again

  repeat
    ReadCleanLn(raFile, raText);
    raStr := ReadStrFromMany(1,raText,' ');

    if raStr = '$variable' then ReadAbsVariable(raFile, raFileName);
    if raStr = '$poly'     then ReadAbsPoly(raFile, raFileName);
    if raStr = '$device'   then ReadAbsDevice(raFile, raFileName);
    if raStr = '$jj'       then ReadAbsJJ(raFile, raFileName);

  until (raStr = '$eof') or (eof(raFile));
  CloseFile(raFile);
end;

end.
