unit AS_Math;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{
    Unit AS_Math (for use with Absynth)
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
  SysUtils, Math, AS_Globals, AS_Utils, AS_Strings;

function EvaluateExpression(eeTest : string; leadingMinus : Double) : Double;
procedure RotatePolygon(var rPoly : TASPolyCoordsReal; rXOrig, rYOrig, rAngle : double);

implementation


{ --------------------------- EvaluateExpression ----------------------------- }
function EvaluateExpression(eeTest : string; leadingMinus : Double) : Double;
// Recursively find value of expression. Operator prededence : / * + -
var
  term1, term2, eeStr, eeTempStr1, eeTempStr2 : string;
  t1, t2 : double;
  ee1, ee2, popen, pclose : integer;
  pOpenFound, pClosedFound : boolean;  
  op : char;
begin
  term1 := ''; term2 := '';
  eeStr := StripSpaces(eeTest);
  eeStr := ReplacePlusMinusArithmeticOps(eeStr);

  // Try to handle parentheses
  if (Length(eeStr) > 1) and (pos('(',eeStr) > 0) then // Cannot open and close parentheses in only one string character
  begin
    pOpenFound := False;
    ee1 := Length(eeStr)-1;
    repeat
      if copy(eeStr,ee1,1) = '(' then    // Last opening parenthesis found - now look for closing parenthesis
      begin
        pOpenFound := True;
        ee2 := ee1+1;
        pClosedFound := False;
        repeat
          if copy(eeStr,ee2,1) = ')' then    // First closing parenthesis found - Now to evaluate the expression within
            pClosedFound := True
          else
            ee2 := ee2+1;
        until (ee2 > Length(eeStr)) or (pClosedFound);
        if not pClosedFound then
          CloseWithHaltCode('Cannot find closing parenthesis in "'+eeStr+'".', 3);
        eeTempStr1 := ''; eeTempStr2 := '';
        pOpenFound := False; pClosedFound := False;
        if ee1 > 1 then
          eeTempStr1 := Copy(eeStr,1,ee1-1);
        if ee2 < Length(eeStr) then
          eeTempStr2 := Copy(eeStr,ee2+1,Length(eeStr)-ee2);
        eeStr := eeTempStr1 + lowercase(FloatToStrF(EvaluateExpression(Copy(eeStr,ee1+1,ee2-ee1-1), 1.0),ffExponent,15,4)) + eeTempStr2;
        eeStr := ReplacePlusMinusArithmeticOps(eeStr);
        ee1 := Length(eeStr);
      end;
      ee1 := ee1-1;
    until (ee1 < 1);
  end;



  if (pos('[',eeStr) > 0) then // character for arithmetic "-" operator
  begin
    t1 := EvaluateExpression(Copy(eeStr,1,pos('[',eeStr)-1), leadingMinus);   // If a leading minus was sent in, pass it down
    t2 := EvaluateExpression(Copy(eeStr,pos('[',eeStr)+1,Length(eeStr)-pos('[',eeStr)), -1.0);
    EvaluateExpression := t1+t2; // We work the "-" into the first variable in the new term...
    exit;
  end
  else if pos(']',eeStr) > 0 then // character for arithmetic "+" operator
  begin
    t1 := EvaluateExpression(Copy(eeStr,1,pos(']',eeStr)-1), leadingMinus);
    t2 := EvaluateExpression(Copy(eeStr,pos(']',eeStr)+1,Length(eeStr)-pos(']',eeStr)), 1.0);
    EvaluateExpression := t1+t2;
    exit;
  end
  else if pos('*',eeStr) > 0 then
  begin
    t1 := EvaluateExpression(Copy(eeStr,1,pos('*',eeStr)-1), leadingMinus);
    t2 := EvaluateExpression(Copy(eeStr,pos('*',eeStr)+1,Length(eeStr)-pos('*',eeStr)), 1.0);
    EvaluateExpression := t1*t2;
    exit;
  end
  else if pos('/',eeStr) > 0 then
  begin
    t1 := EvaluateExpression(Copy(eeStr,1,pos('/',eeStr)-1), leadingMinus);
    t2 := EvaluateExpression(Copy(eeStr,pos('/',eeStr)+1,Length(eeStr)-pos('/',eeStr)), 1.0);
    EvaluateExpression := t1/t2;
    exit;
  end
  else
  begin // No operator - evaluate variable
    if eeStr <> '' then
    begin
      if eeStr[1] = '%' then
        EvaluateExpression := leadingMinus * ReadVariableValue(eeStr)
      else
      begin
        if CheckIfReal(eeStr) then
          EvaluateExpression := leadingMinus * StrToFloat(eeStr)
        else
          CloseWithHaltCode('Cannot parse variable '+eeStr+'. Did you forget "%"?', 61);
      end;
    end
    else
      EvaluateExpression := 0; // Not a good idea... change to error
    exit;
  end;
end; // EvaluateExpression
{ ------------------------------ RotatePolygon ------------------------------- }
procedure RotatePolygon(var rPoly : TASPolyCoordsReal; rXOrig, rYOrig, rAngle : double);

var
  r1 : integer;
  rX, rY : double;
begin
  if abs(rAngle) > 1e-10 then
    for r1 := 0 to High(rPoly) do
    begin
      rX := rPoly[r1].x - rXOrig;
      rY := rPoly[r1].y - rYOrig;
      rPoly[r1].x := rX*cos(rAngle*pi/180) - rY*sin(rAngle*pi/180) + rXOrig;
     rPoly[r1].y := rY*cos(rAngle*pi/180) + rX*sin(rAngle*pi/180) + rYOrig;
    end;
end;

end.
