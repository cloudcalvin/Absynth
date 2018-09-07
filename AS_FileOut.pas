unit AS_FileOut;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{
    Unit AS_FileOut (for use with Absynth)
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
  SysUtils, Math, AS_Globals, AS_Utils;

procedure WriteGDSHeader;
procedure WriteObjectsToGDS(gdsFileName : string);


implementation

var
  fi1 : Integer;


{ ----------------------------- WriteGDSHeader ------------------------------- }
procedure WriteGDSHeader;

var
//  woRecordLength, woRecordType, wo1, wo2 : integer;
  wg1 : integer;
  wgYear, wgMonth, wgDay, wgHour, wgMinute, wgSecond, wgMillisecond : word;
  wgDummy, wgByte1, wgByte2, wgByte3, wgByte4 : byte;
  wgChar : char;
  wgStr, wgNameStr : shortstring;
  wgTime : TDateTime;
begin
  wgByte1 := 0; wgByte2 := 6; // length of HEADER
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := 0; wgByte2 := 2; // HEADER
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := 0; wgByte2 := 7; // stream version (GDSII version 7)
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := 0; wgByte2 := 28; // Length of LIB
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := 1; wgByte2 := 2; // BGNLIB
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgTime := Time;
  DecodeDate(wgTime, wgYear,wgMonth,wgDay);
  DecodeTime(wgTime, wgHour,wgMinute,wgSecond,wgMillisecond);
  // Use DecodeDate and DecodeTime from "SysUtils" to avoid compiling in "DateUtils"
  for wg1 := 1 to 2 do   // Write date/time twice ("create" and "last access")
  begin
    WordToBytes(wgYear, wgByte1, wgByte2);
    Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
    WordToBytes(wgMonth, wgByte1, wgByte2);
    Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
    WordToBytes(wgDay, wgByte1, wgByte2);
    Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
    WordToBytes(wgHour, wgByte1, wgByte2);
    Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
    WordToBytes(wgMinute, wgByte1, wgByte2);
    Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
    WordToBytes(wgSecond, wgByte1, wgByte2);
    Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  end; // for woti := 1 to 2
  wgNameStr := libName+'.DB';
  wgByte1 := 0; wgByte2 := 16; // Length of LIBNAME
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := 2; wgByte2 := 6; // BGNLIB
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  for wg1 := 1 to length(wgNameStr) do // write out string character by character
  begin
    wgStr := copy(wgNameStr,wg1,1);
    wgDummy := ord(wgStr[1]);
    Write(gdsOutFile,wgDummy);
  end;
  wgDummy := 0; Write(gdsOutFile,wgDummy); // write blank character to make even length record for XIC
  wgByte1 := 0; wgByte2 := 20; // Length of UNITS
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := 3; wgByte2 := 5; // UNITS
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := $3E; wgByte2 := $41; // DBUSERUNITS
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := $89; wgByte2 := $37; // DBUSERUNITS
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := $4B; wgByte2 := $C6; // DBUSERUNITS
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := $A7; wgByte2 := $F0; // DBUSERUNITS
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := $39; wgByte2 := $44; // DBUNITSPERMETRE
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := $B8; wgByte2 := $2F; // DBUNITSPERMETRE
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := $A0; wgByte2 := $9B; // DBUNITSPERMETRE
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := $5A; wgByte2 := $54; // DBUNITSPERMETRE
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := 0; wgByte2 := 28; // Length of STR
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
  wgByte1 := 5; wgByte2 := 2; // STR
  Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
//  DecodeDateTime(wgTime, wgYear,wgMonth,wgDay,wgHour,wgMinute,wgSecond,wgMillisecond);  // requires "DateUtils"
  for wg1 := 1 to 2 do   // Write date/time twice ("create" and "last access")
    begin
      WordToBytes(wgYear, wgByte1, wgByte2);
      Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
      WordToBytes(wgMonth, wgByte1, wgByte2);
      Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
      WordToBytes(wgDay, wgByte1, wgByte2);
      Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
      WordToBytes(wgHour, wgByte1, wgByte2);
      Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
      WordToBytes(wgMinute, wgByte1, wgByte2);
      Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
      WordToBytes(wgSecond, wgByte1, wgByte2);
      Write(gdsOutFile,wgByte1); Write(gdsOutFile,wgByte2);
    end; // for wg1 := 1 to 2

end; // WriteGDSHeader
{ --------------------------- WriteObjectsToGDS ------------------------------ }
procedure WriteObjectsToGDS(gdsFileName : string);

var
  woRecordLength, woRecordType, wo1, wo2 : integer;
  woYear, woMonth, woDay, woHour, woMinute, woSecond, woMillisecond : word;
  woDummy, woByte1, woByte2, woByte3, woByte4 : byte;
  woChar : char;
  woStr, woNameStr : shortstring;
  woTime : TDateTime;

  woStructNameDummy : string;
begin
  woStructNameDummy := structName;

  AssignFile(gdsOutFile,gdsFileName);
  {$I-}
  rewrite(gdsOutFile);
  {$I+}
  WriteGDSHeader;

  woByte1 := 0; woByte2 := 4 + Length(woStructNameDummy); // length of structure name [+ 1 for #0 character] and + 4 for record header
  if (woByte2 mod 2) <> 0 then inc(woByte2); // make it even for XIC
  Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
  woByte1 := 6; woByte2 := 6; // STRNAME record type [ 0x0606 ]
  Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
  for wo1 := 1 to length(woStructNameDummy) do // write out string character by character
    begin
      woStr := copy(woStructNameDummy,wo1,1);
      woDummy := ord(woStr[1]);
      Write(gdsOutFile,woDummy);
    end;
  woDummy := 0; // #0 character
//  Write(gdsOutFile,woDummy);
  if (Length(woStructNameDummy) mod 2) <> 0 then Write(gdsOutFile,woDummy); // write extra #0 to even out the record for XIC
  for wo1 := 0 to High(polys) do


    begin // write out blocks
      if polys[wo1].Layer = -1 then Continue;  // disregard layers "killed" during via-to-terminal transformation
      woByte1 := 0; woByte2 := 4; // length of BOUNDARY record
      Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
      woByte1 := 8; woByte2 := 0; // BOUNDARY record type [ 0x0800 ]
      Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
      woByte1 := 0; woByte2 := 6; // length of LAYER record
      Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
      woByte1 := 13; woByte2 := 2; // LAYER record type [ 0x0D02 ]
      Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
      woByte1 := 0; woByte2 := polys[wo1].Layer;
      Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
      woByte1 := 0; woByte2 := 6; // length of DATATYPE record
      Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
      woByte1 := 14; woByte2 := 2; // DATATYPE record type [ 0x0E02 ]
      Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
      woByte1 := 0; woByte2 := 0; //
      Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
{      woByte1 := 0; woByte2 := 44; // length of XY record}
      woByte1 := ((4 + 8*Length(polys[wo1].Coords)) div 256);
      woByte2 := ((4 + 8*Length(polys[wo1].Coords)) mod 256);
      Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
      woByte1 := 16; woByte2 := 3; // XY record type [ 0x1003 ]
      Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
        // write full set of XY coordinates to define boundary / polygon
      for wo2 := 0 to High(polys[wo1].Coords) do
        begin
          Chop4ByteInt(polys[wo1].Coords[wo2].x, woByte1, woByte2, woByte3, woByte4);
          Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2); Write(gdsOutFile,woByte3); Write(gdsOutFile,woByte4);
          Chop4ByteInt(polys[wo1].Coords[wo2].y, woByte1, woByte2, woByte3, woByte4);
          Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2); Write(gdsOutFile,woByte3); Write(gdsOutFile,woByte4);
        end;
      woByte1 := 0; woByte2 := 4; // length of ENDEL record
      Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
      woByte1 := 17; woByte2 := 0; // ENDEL record type [ 0x1100 ]
      Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
    end;


  woByte1 := 0; woByte2 := 4; // length of ENDSTR record
  Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
  woByte1 := 7; woByte2 := 0; // ENDSTR record type [ 0x0700 ]
  Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
  woByte1 := 0; woByte2 := 4; // length of ENDLIB record
  Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);
  woByte1 := 4; woByte2 := 0; // ENDLIB record type [ 0x0400 ]
  Write(gdsOutFile,woByte1); Write(gdsOutFile,woByte2);


  CloseFile(gdsOutFile);
end; // WriteObjectsToGDS


end.
