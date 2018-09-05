program Absynth;

{$APPTYPE CONSOLE}

{*******************************************************************************
*                                                                              *
* Author    :  Coenrad Fourie                                                  *
* Version   :  0.1                                                             *
* Date      :  November 2017                                                   *
* Copyright (c) 2017-2018 Coenrad Fourie                                       *
*                                                                              *
* Layout synthesizer for SCE devices, circuits and SFQ logic cells.            *
* Developed originally under IARPA-BAA-16-03                                   *
*                                                                              *
* Last modification: 28 November 2017                                          *
*      Junction area synthesis                                                 *
*                                                                              *
********************************************************************************}

{$IFDEF MSWINDOWS}
{$DEFINE Windows}
{$APPTYPE CONSOLE}
{$ENDIF MSWINDOWS}


{$R *.res}

uses
  {$IFDEF MSWINDOWS}
  System.SysUtils,
  System.Math,
  {$ELSE}
  SysUtils,
  {$ENDIF }
  AS_FileIn in 'AS_FileIn.pas',
  AS_FileOut in 'AS_FileOut.pas',
  AS_Globals in 'AS_Globals.pas',
  AS_Strings in 'AS_Strings.pas',
  AS_Utils in 'AS_Utils.pas',
  AS_Synth in 'AS_Synth.pas',
  AS_Math in 'AS_Math.pas';

{ -------------------------------- BlurbHelp --------------------------------- }
procedure BlurbHelp;

begin
  Writeln; WriteLn('Absynth synthesizes SCE circuit layouts to GDS2 files.');
  WriteLn;
  WriteLn(' Options: (Case senstive arguments.)');
  WriteLn('  -a filename.abs = Parmeterized ABS input script file for cell or device.');
  WriteLn('  -o filename.gds = GDS2 output file to write to.');
  WriteLn('  -p filename.prd = Process description file.');
  WriteLn('  -v              = Verbose mode on.');
  WriteLn; WriteLn('For user support, e-mail your questions to coenrad@sun.ac.za'); WriteLn;
end; // BlurbHelp
{ ------------------------------ CloseAbsynth -------------------------------- }
procedure CloseAbsynth;

begin
  WriteWarningsAndErrors;
  CleanMemory;
  if TTextRec(outFile).Mode <> fmClosed then
    CloseFile(outFile);
  Halt(0);
end; // CloseAbsynth
{ -------------------------------- Initiate ---------------------------------- }
procedure Initiate;
// Set variables at startup
var
  i1 : Integer;
  textLine : String;
begin
  {  START Variable initiation  }
  absFileParam := 0;
  gdsOutFileParam := 0;
  processFileParam := 0;
  absFileName := '';
  gdsOutFileName := '';
  processFileName := '';
  structName := 'absynth_default';
  unitSize := UNITSIZEINMETRES;
  drawScale := DEFAULTDRAWUNITSPERLENGTHUNIT;
  drawScaleInt := Round(drawScale);
  libName := 'COLDFLUX';
  SetLength(warningStrings,0);
  SetLength(errorStrings,0);
  SetLength(paramVariable,1);
  SetLength(devJJ,0);
  paramVariable[0].name := 'pi';
  paramVariable[0].value := pi;
  verboseOn := false;
  for i1 := 0 to MAXGDSLAYERS do
    with layer[i1] do
    begin
      Number := -1;
      Name := '';
      Typ := LAYERUNDEF;
      Jc := DEFAULTPROCESSJC;
      Dc := 0;
      B := 0;
      GridSize := 0.025;
      MinSize := 1.0;
      MaxSize := -1;
      MaxWidth := -1;
      SetLength(Surround,0);
      SetLength(MinSpace,0);
    end;
  {  END Variable initiation  }
  FormatSettings.DecimalSeparator := '.';  // Make SURE that OS localization is overloaded with our default,
        // otherwise floating point numbers cannot be read from strings in France / Germany
  // Assign output filef
  AssignFile(outFile,'absynth_out.txt');
  {$I-}
  rewrite(outFile);
  {$I+}
  EchoLn('Absynth v' + VersionNumber + ' ('+BuildDate+'). ' + CopyrightNotice);
  // Write License notice
  WriteLn;
  WriteLn('This program comes with ABSOLUTELY NO WARRANTY.');
  WriteLn;
  // Read Parameters
  if ParamCount < 2 then
  begin
    Writeln('Parameter required, e.g.');
    Writeln('  absynth -a and2.abs [-o and2.gds] [-p mitll.prd]');
    Writeln; WriteLn('  Type ''absynth -h'' or ''absynth /?'' or ''absynth -?'' for help.'); Writeln; halt(0);
  end
  else
    if (ParamStr(1) = '-h') or (ParamStr(1) = '-?') or (ParamStr(1) = '/h') or (ParamStr(1) =  '/?') or (ParamStr(1) = '-H') or (ParamStr(1) = '/H') then
    begin
      BlurbHelp; halt(0);
    end;
  for i1 := 1 to ParamCount do
  begin
    if ParamStr(i1) = '-a' then absFileParam := i1+1;
    if ParamStr(i1) = '-o' then gdsOutFileParam := i1+1;
    if ParamStr(i1) = '-p' then processFileParam := i1+1;
    if ParamStr(i1) = '-v' then verboseOn := true;
  end;
  if absFileParam < 1 then
    CloseWithHaltCode('No .abs input file specified.', 7)
  else
    absFileName := ParamStr(absFileParam);
  if gdsOutFileParam > 0 then
    gdsOutFileName := ParamStr(gdsOutFileParam)
  else
    gdsOutFileName := Copy(absFileName,1,pos('.',absFileName)) + '.gds';
  if processFileParam > 0 then
    processFileName := ParamStr(processFileParam);
end; // Initiate
{ ================================   MAIN   ================================== }

begin
  try
    Initiate;
    ReadAbsScript(absFileName);
    WriteObjectsToGDS(gdsOutFileName);
  except
    on E: Exception do
    begin
      Echoln(E.ClassName+': '+E.Message);
      CloseAbsynth;
    end;
  end;
  CloseAbsynth;
end.
