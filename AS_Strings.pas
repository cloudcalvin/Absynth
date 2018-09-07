unit AS_Strings;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

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
  SysUtils, Math, AS_Globals, AS_FileOut, AS_Utils, StrUtils;

function StripSpaces(FullString : string) : string;
function StripMinus(FullString : string) : string;
function StringToDouble(txtext : string) : double;
function ReadRealFromText(txtext : string; varDefault : double; errorText : string) : double;
function ReadIntFromText(txtext : string; varDefault : integer; errorText : string) : integer;
function ReadStrFromText(rsText : string) : string;
function ReadValueAfterEqualSign(rText, rIdentifier : string) : string;
function ReadStrFromMany(txIndex : integer; txtext, txSeparator : string) : string;
function CountSubstrings(cText, cSeparator : String) : Integer;
function ReadLastStrFromMany(var txtext : string; txSeparator : string; txWipe : boolean) : string;
function CreateTab(txSpaces : Integer) : string;
procedure AddValueToTextString(avValue : Double; var avTeks : string; avMinValue : Double; avExceptTeks : string; avPrecision, avDigits, avTrimLength, avPadLength : Integer);
function StringIsDigit(siChar : Char) : boolean;
function ReplacePlusMinusArithmeticOps(rpStr : string) : string;


implementation

{ ------------------------------ StripSpaces --------------------------------- }
function StripSpaces(FullString : string) : string;

var
  fstr : string;
begin
  fstr := FullString;
  while (copy(fstr,1,1) = ' ') or (copy(fstr,1,1) = #9) do
    delete(fstr,1,1);                // strip leading spaces
  while (copy(fstr,length(fstr),1) = ' ') or (copy(fstr,length(fstr),1) = #9) do
    delete(fstr,length(fstr),1);  // strip trailing spaces
  StripSpaces := fstr;
end;  // StripSpaces
{ ------------------------------- StripMinus --------------------------------- }
function StripMinus(FullString : string) : string;

var
  fstr : string;
begin
  fstr := FullString;
  if (copy(fstr,1,1) = '-') then
    delete(fstr,1,1);                // strip leading minus
  StripMinus := fstr;
end;  // StripMinus
{ ----------------------------- StringToDouble ------------------------------- }
function StringToDouble(txtext : string) : double;

var
  stdMultiplier, stdValue : Double;
  std1 : Integer;
  suffixFound : Boolean;
begin
  suffixFound := False;  stdMultiplier := 1;
  for std1 := 1 to Length(txtext) do
    if not ((ord(txtext[std1]) in [48..57]) or (txtext[std1] in ['.', ',', 'e', 'E', '+', '-'])) then
    begin
      if LowerCase(txtext[std1]) = 'a' then
      begin
        stdMultiplier := 1E-18; suffixFound := True;
      end;
      if LowerCase(txtext[std1]) = 'f' then
      begin
        stdMultiplier := 1E-15; suffixFound := True;
      end;
      if LowerCase(txtext[std1]) = 'p' then
      begin
        stdMultiplier := 1E-12; suffixFound := True;
      end;
      if LowerCase(txtext[std1]) = 'n' then
      begin
        stdMultiplier := 1E-9; suffixFound := True;
      end;
      if LowerCase(txtext[std1]) = 'u' then
      begin
        stdMultiplier := 1E-6; suffixFound := True;
      end;
      if LowerCase(txtext[std1]) = 'm' then
      begin
        if LowerCase(copy(txtext,std1,3)) = 'meg' then
          stdMultiplier := 1E6
        else
          stdMultiplier := 1E-3;
        suffixFound := True;
      end;
      if LowerCase(txtext[std1]) = 'k' then
      begin
        stdMultiplier := 1E3; suffixFound := True;
      end;
      if LowerCase(txtext[std1]) = 'g' then
      begin
        stdMultiplier := 1E9; suffixFound := True;
      end;
      break;
    end;
  if not suffixFound then
  begin
    if CheckIfReal(txtext) then
      stdValue := StrToFloat(txtext)
    else
      stdValue := 0;
  end
  else
    if CheckIfReal(copy(txtext,1,std1-1)) then
      stdValue := StrToFloat(copy(txtext,1,std1-1))
    else
      stdValue := 0;
  StringToDouble := stdValue*stdMultiplier;
end; // StringToDouble
{ ---------------------------- ReadRealFromText ------------------------------ }
function ReadRealFromText(txtext : string; varDefault : double; errorText : string) : double;

begin
  if CheckIfReal(StripSpaces(copy(txtext,pos('=',txtext)+1,length(txtext)-pos('=',txtext)))) then
    ReadRealFromText := StrToFloat(StripSpaces(copy(txtext,pos('=',txtext)+1,length(txtext)-pos('=',txtext))))
  else
  begin
    EchoLn(errorText+' Default value of '+FloatToStrF(varDefault,ffGeneral,6,6)+' assigned.');
    ReadRealFromText := varDefault;
  end;
end;  // ReadRealFromText
{ ----------------------------- ReadIntFromText ------------------------------ }
function ReadIntFromText(txtext : string; varDefault : integer; errorText : string) : integer;

begin
  if CheckIfInteger(StripSpaces(copy(txtext,pos('=',txtext)+1,length(txtext)-pos('=',txtext)))) then
    ReadIntFromText := StrToInt(StripSpaces(copy(txtext,pos('=',txtext)+1,length(txtext)-pos('=',txtext))))
  else
  begin
    EchoLn(errorText+' Default value of '+IntToStr(varDefault)+' assigned.');
    ReadIntFromText := varDefault;
  end;
end;  // ReadRealFromText
{ ----------------------------- ReadStrFromText ------------------------------ }
function ReadStrFromText(rsText : string) : string;

var
  rsStr : string;
begin
  if StripSpaces(copy(rsText,pos('=',rsText)+1,length(rsText)-pos('=',rsText))) = '' then
    rsStr := ' ' // pass back a space so that it is not empty
  else
    rsStr := lowercase(StripSpaces(copy(rsText,pos('=',rsText)+1,length(rsText)-pos('=',rsText))));
  if pos('"',rsStr) > 0 then
  begin
    rsStr := copy(rsStr,pos('"',rsStr)+1,length(rsStr)-pos('"',rsStr));
    if pos('"',rsStr) > 0 then
      rsStr := copy(rsStr,1,pos('"',rsStr)-1)
    else
      rsStr := ' ';
  end;
  ReadStrFromText := rsStr;
end;  // ReadStrFromText
{ ------------------------- ReadValueAfterEqualSign -------------------------- }
function ReadValueAfterEqualSign(rText, rIdentifier : string) : string;
// Read string value after the '=' in a string that follows directly after the identifier substring
var
  rTrim : String;
begin
  if pos(rIdentifier,rText) < 1 then
  begin
    ReadValueAfterEqualSign := '';
    exit;
  end;
  Delete(rText,1,pos(rIdentifier,rText)-1);
  Delete(rText,1,pos('=',rText));
  rText := StripSpaces(rText);
  if pos(' ',rText) > 0 then
    Delete(rText,1,pos(' ',rText)-1);
  ReadValueAfterEqualSign := rText;
end; // ReadValueAfterEqualSign
{ ---------------------------- ReadStrFromMany ------------------------------- }
function ReadStrFromMany(txIndex : integer; txtext, txSeparator : string) : string;

var
  txOrig, txRes : string;
  tx1 : Integer;
begin
  txOrig := txtext; txRes := ' '; // Don't send back an empty string...
  for tx1 := 1 to (txIndex-1) do
  begin
    if pos(txSeparator,txOrig) = 0 then
    begin
      ReadStrFromMany := ' ';
      exit;
    end;
    txOrig := copy(txOrig,pos(txSeparator,txOrig)+1,length(txOrig)-pos(txSeparator,txOrig));
    while copy(txOrig,1,1) = txSeparator do
      Delete(txOrig,1,1);
    if txOrig = '' then
    begin
      ReadStrFromMany := ' ';
      exit;
    end;
  end;
  if StripSpaces(txOrig) = '' then
    ReadStrFromMany := ' ' // pass back a space so that it is not empty
  else
  begin
    if pos(txSeparator,txOrig) > 0 then
      txOrig := copy(txOrig,1,pos(txSeparator,txOrig)-1);
    txOrig := lowercase(StripSpaces(txOrig));
    if pos('=',txOrig) > 0 then
      txOrig := copy(txOrig,1,pos('=',txOrig)-1);  // Remove "=" sign if present
    ReadStrFromMany := txOrig;
  end;
end;  // ReadStrFromMany
{ ----------------------------- CountSubstrings ------------------------------ }
function CountSubstrings(cText, cSeparator : String) : Integer;

var
  cCount : Integer;
begin
  cCount := 0;
  while ReadStrFromMany(cCount+1,cText,cSeparator) <> ' ' do
  begin
    inc(cCount);
    if cCount > 1024 then
      Break;  // Failsafe. Strings surely won't have that many substrings.
  end;
  CountSubstrings := cCount;
end; // CountSubstrings
{ --------------------------- ReadLastStrFromMany ---------------------------- }
function ReadLastStrFromMany(var txtext : string; txSeparator : string; txWipe : boolean) : string;

var
  txRes : string;
  tx1 : Integer;
begin
  txtext := StripSpaces(txtext); txRes := ' '; // Don't send back an empty string...
  tx1 := Length(txtext);
  while not (copy(txtext,tx1,1) = txSeparator) do
    dec(tx1,1);
  if tx1= 0 then
    txRes := ' '
  else
  begin
    txRes := copy(txtext,tx1,length(txtext)-tx1+1);
    if txWipe then
      Delete(txtext,tx1,length(txtext)-tx1+1);
  end;
  if StripSpaces(txRes) = '' then
    ReadLastStrFromMany := ' ' // pass back a space so that it is not empty
  else
    ReadLastStrFromMany := lowercase(StripSpaces(txRes));
end;  // ReadLastStrFromMany
{ ------------------------------ txCreateTab --------------------------------- }
function CreateTab(txSpaces : Integer) : string;

var
  cti : Integer;
  cts : String;
begin
  cts := '';
  for cti := 1 to txSpaces do
    cts := cts + ' ';
  CreateTab := cts;
end;  // CreateTab
{ -------------------------- AddValueToTextString ---------------------------- }
procedure AddValueToTextString(avValue : Double; var avTeks : string; avMinValue : Double; avExceptTeks : string; avPrecision, avDigits, avTrimLength, avPadLength : Integer);

begin
  if abs(avValue) > avMinValue then
    avTeks := avTeks + FloatToStrF(avValue,ffFixed,avPrecision,avDigits)
  else avTeks := avTeks + avExceptTeks;
  while (Length(avTeks) > (avTrimLength+1)) and (copy(avTeks,length(avTeks),1) <> '.') do    // don't make shorter than integer part
    Delete(avTeks,Length(avTeks),1);
  if Length(avTeks) > avTrimLength then
    Delete(avTeks,Length(avTeks),1);  // trim last digit, especially if it is just '.'
  if avTeks[length(avTeks)] = '.' then
    Delete(avTeks,Length(avTeks),1);  // trim '.' if that is the last character
  while length(avTeks) < avPadLength do
    avTeks := avTeks+' ';
end;  // AddValueToTextString
{ ---------------------------- StringIsDigit --------------------------------- }
function StringIsDigit(siChar : Char) : boolean;

begin
  if siChar in ['0'..'9'] then
    StringIsDigit := True
  else
    StringIsDigit := False;
end;
{ ---------------------- ReplacePlusMinusArithmeticOps ----------------------- }
function ReplacePlusMinusArithmeticOps(rpStr : string) : string;
// Replace "-" with "[" and "+" with "]" in strings to prevent Expression Evaluation clashes with E+ and E- in scientific notation
var
  rp1 : integer;
  rpNewStr : string;
begin
  if rpStr = '' then
  begin
    ReplacePlusMinusArithmeticOps := '';
    exit;
  end;
  rpNewStr := '';
  for rp1 := 1 to (Length(rpStr)-1) do
  begin
    if rpStr[rp1] = '-' then
    begin
      if Length(rpStr) > 3 then
        if not ((rpStr[rp1-1] in ['e','E']) and (StringIsDigit(rpStr[rp1-2]) and StringIsDigit(rpStr[rp1+1]))) then
          rpNewStr := rpNewStr + '['
        else
          rpNewStr := rpNewStr + '-'
      else
        rpNewStr := rpNewStr + '[';
    end
    else
    begin
      if rpStr[rp1] = '+' then
      begin
        if Length(rpStr) > 3 then
          if not ((rpStr[rp1-1] in ['e','E']) and (StringIsDigit(rpStr[rp1-2]) and StringIsDigit(rpStr[rp1+1]))) then
            rpNewStr := rpNewStr + ']'
          else
            rpNewStr := rpNewStr + '+'
        else
          rpNewStr := rpNewStr + ']';
      end
      else
        rpNewStr := rpNewStr + rpStr[rp1];
    end;
  end;
  rpNewStr := rpNewStr + rpStr[Length(rpStr)];
  ReplacePlusMinusArithmeticOps := rpNewStr;
end;

end.
