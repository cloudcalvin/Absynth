unit AS_Synth;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{
    Unit AS_Synth (for use with Absynth)
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
  SysUtils, Math, AS_Globals, AS_FileOut, AS_Math, AS_Utils;

procedure SynthMCircle(smX, smY, smR, smGrid : double; var smCoords : TASPolyCoords);
procedure SynthCircle(scX, scY, scR, scGrid : double; scSteps : integer; var scCoords : TASPolyCoords);
procedure SynthRectangle(srX, srY, srRotX, srRotY, srRotAngle, srX1, srY1, srX2, srY2, srGrid : double; var srCoords : TASPolyCoords);
procedure SynthJJ(sjDef : string; sjX, sjY, sjRotate : double; var sjParams : TDevParamArray);


implementation

{ ------------------------------ SynthMCircle -------------------------------- }
procedure SynthMCircle(smX, smY, smR, smGrid : double; var smCoords : TASPolyCoords);

var
  smLastX, smLastY, smNewX, smNewY, sm1, smCircleSteps : integer;
  smAngleDelta : double;
begin
  SetLength(smCoords,1);
  smCoords[0].x := ClosestGridPoint(smX*drawScale,smGrid*drawScale);
  smCoords[0].y := ClosestGridPoint((smY-smR)*drawScale,smGrid*drawScale);
  smLastX := smCoords[0].x;
  smLastY := smCoords[0].y;
  smAngleDelta := smGrid/(2*smR);
  smCircleSteps := Round(2*pi/smAngleDelta);
  for sm1 := 1 to (smCircleSteps-1) do
  begin
    smNewX := smCoords[0].x + ClosestGridPoint(sin(smAngleDelta*sm1)*smR*drawScale,smGrid*drawScale);
    smNewY := smCoords[0].y + ClosestGridPoint((smR*drawScale-cos(smAngleDelta*sm1)*smR*drawScale),smGrid*drawScale);
    if (smNewX <> smLastX) and (smNewY <> smLastY) then
    begin
      SetLength(smCoords, Length(smCoords)+2);
      if abs(smNewX-smLastX) >= abs(smNewY-smLastY) then
      begin
        smCoords[High(smCoords)-1].x := smNewX;
        smCoords[High(smCoords)-1].y := smLastY;
      end
      else
      begin
        smCoords[High(smCoords)-1].x := smLastX;
        smCoords[High(smCoords)-1].y := smNewY;
      end;
      smCoords[High(smCoords)].x := smNewX;
      smCoords[High(smCoords)].y := smNewY;
      smLastX := smNewX;
      smLastY := smNewY;
    end;
  end;
  SetLength(smCoords, Length(smCoords)+1);
  smCoords[High(smCoords)].x := smCoords[0].x;
  smCoords[High(smCoords)].y := smCoords[0].y;
end; // SynthMCircle
{ ------------------------------- SynthCircle -------------------------------- }
procedure SynthCircle(scX, scY, scR, scGrid : double; scSteps : integer; var scCoords : TASPolyCoords);

var
  sc1 : integer;
begin
  SetLength(scCoords,1);
  scCoords[0].x := ClosestGridPoint(scX*drawScale,scGrid*drawScale);
  scCoords[0].y := ClosestGridPoint((scY-scR)*drawScale,scGrid*drawScale);
  for sc1 := 1 to (scSteps-1) do
  begin
    SetLength(scCoords, Length(scCoords)+1);
    scCoords[High(scCoords)].x := scCoords[0].x + Round(sin(2*pi/scSteps*sc1)*scR*drawScale);
    scCoords[High(scCoords)].y := scCoords[0].y + Round((scR*drawScale-cos(2*pi/scSteps*sc1)*scR*drawScale));
  end;
  SetLength(scCoords, Length(scCoords)+1);
  scCoords[High(scCoords)].x := scCoords[0].x;
  scCoords[High(scCoords)].y := scCoords[0].y;
end; // SynthCircle
{ ------------------------------ SynthRectangle ------------------------------ }
procedure SynthRectangle(srX, srY, srRotX, srRotY, srRotAngle, srX1, srY1, srX2, srY2, srGrid : double; var srCoords : TASPolyCoords);

var
  sc1 : integer;
  srPoly : TASPolyCoordsReal;
begin
  SetLength(srPoly,5);
  srPoly[0].x := srX1;
  srPoly[0].y := srY1;
  srPoly[1].x := srX2;
  srPoly[1].y := srY1;
  srPoly[2].x := srX2;
  srPoly[2].y := srY2;
  srPoly[3].x := srX1;
  srPoly[3].y := srY2;
  srPoly[4].x := srX1;
  srPoly[4].y := srY1;
  RotatePolygon(srPoly,srRotX,srRotY,srRotAngle);
  SetLength(srCoords,5);
  for sc1 := 0 to High(srPoly) do
  begin
    srCoords[sc1].x := ClosestGridPoint((srX+srPoly[sc1].x)*drawScale,srGrid*drawScale);
    srCoords[sc1].y := ClosestGridPoint((srY+srPoly[sc1].y)*drawScale,srGrid*drawScale);
  end;
end; // SynthCircle
{ -------------------------------- SynthJJ ----------------------------------- }
procedure SynthJJ(sjDef : string; sjX, sjY, sjRotate : double; var sjParams : TDevParamArray);

var
  sj1, sjJ : integer;
  sjArea, sjJJDiameterWafer, sjJJDiameterDraw, sjRectangleX1, sjRectangleX2, sjRectangleY1, sjRectangleY2 : double;
  sjVarBaseX, sjVarBaseY, sjVarCounterX, sjVarCounter2X, sjVarCounterY, sjVarResY, sjVarRSViaX, sjVarRSVia1Y, sjVarRSVia2Y, sjVarCBViaX, sjVarCBViaY : double;
  sjVarLowerGndViaY : double;
  sjMinResLength, sjMinResWidth : double;
begin
  sjJ := -1;
  for sj1 := 0 to High(devJJ) do
    if devJJ[sj1].Name = sjDef then
      sjJ := sj1;
  if sjJ < 0 then
  begin
    AddErrorString('JJ device '+sjDef+' not defined. Ignored');
    exit;
  end;
  if Length(sjParams) = 0 then
  begin
    AddErrorString('Critical current for JJ device '+sjDef+' not specified . Device Ignored');
    exit;
  end;
  // Now synthesize the junction.
  sjArea := GetDeviceParameter('icrit',sjParams)/layer[devJJ[sjJ].JJ.Layer].Jc;
  sjJJDiameterWafer := 2*(sqrt(sjArea/pi));
  sjJJDiameterDraw := sqrt((sjJJDiameterWafer-layer[devJJ[sjJ].JJ.Layer].b)*(sjJJDiameterWafer-layer[devJJ[sjJ].JJ.Layer].b)
                      +layer[devJJ[sjJ].JJ.Layer].dc*layer[devJJ[sjJ].JJ.Layer].dc);
  SetLength(polys,Length(polys)+1);
  polys[High(polys)].Layer := devJJ[sjJ].JJ.Layer;
  if devJJ[sjJ].JJ.Shape = SHAPEMCIRCLE then
    SynthMCircle(sjX, sjY, sjJJDiameterDraw/2+devJJ[sjJ].JJ.Offset, layer[devJJ[sjJ].JJ.Layer].GridSize, polys[High(polys)].Coords);
  if devJJ[sjJ].JJ.Shape = SHAPECIRCLE then
    SynthCircle(sjX, sjY, sjJJDiameterDraw/2+devJJ[sjJ].JJ.Offset, layer[devJJ[sjJ].JJ.Layer].GridSize, devJJ[sjJ].JJ.CirclePoints, polys[High(polys)].Coords);
  if devJJ[sjJ].JJ.Shape = SHAPEUNDEF then
  begin
    AddErrorString('Layer '+IntToStr(devJJ[sjJ].JJ.Layer)+' shape in '+sjDef+' not defined. Ignored.');
    SetLength(polys,Length(polys)-1);
  end;
  if Length(devJJ[sjJ].Objects) > 0 then
    for sj1 := 0 to High(devJJ[sjJ].Objects) do
    begin
      SetLength(polys,Length(polys)+1);
      polys[High(polys)].Layer := devJJ[sjJ].Objects[sj1].Layer;
      if devJJ[sjJ].Objects[sj1].Shape = SHAPEMCIRCLE then
        SynthMCircle(sjX, sjY, sjJJDiameterDraw/2+devJJ[sjJ].Objects[sj1].Offset, layer[devJJ[sjJ].Objects[sj1].Layer].GridSize, polys[High(polys)].Coords);
      if devJJ[sjJ].Counter.Shape = SHAPECIRCLE then
        SynthCircle(sjX, sjY, sjJJDiameterDraw/2+devJJ[sjJ].Objects[sj1].Offset, layer[devJJ[sjJ].Objects[sj1].Layer].GridSize, devJJ[sjJ].Objects[sj1].CirclePoints, polys[High(polys)].Coords);
      if devJJ[sjJ].Counter.Shape = SHAPEUNDEF then
      begin
        AddErrorString('Layer '+IntToStr(devJJ[sjJ].Objects[sj1].Layer)+' shape in '+sjDef+' not defined. Ignored.');
        SetLength(polys,Length(polys)-1);
      end;
    end;
  if abs(GetDeviceParameter('rs',sjParams)) < 1e-17 then  // No shunt resistor
  begin
    SetLength(polys,Length(polys)+1);
    polys[High(polys)].Layer := devJJ[sjJ].Base.Layer;
    if devJJ[sjJ].Base.Shape = SHAPEMCIRCLE then
      SynthMCircle(sjX, sjY, sjJJDiameterDraw/2+devJJ[sjJ].Base.Offset, layer[devJJ[sjJ].Base.Layer].GridSize, polys[High(polys)].Coords);
    if devJJ[sjJ].Base.Shape = SHAPECIRCLE then
      SynthCircle(sjX, sjY, sjJJDiameterDraw/2+devJJ[sjJ].Base.Offset, layer[devJJ[sjJ].Base.Layer].GridSize, devJJ[sjJ].Base.CirclePoints, polys[High(polys)].Coords);
    if devJJ[sjJ].Base.Shape = SHAPEUNDEF then
    begin
      AddErrorString('Layer '+IntToStr(devJJ[sjJ].Base.Layer)+' shape in '+sjDef+' not defined. Ignored.');
      SetLength(polys,Length(polys)-1);
    end;
    SetLength(polys,Length(polys)+1);
    polys[High(polys)].Layer := devJJ[sjJ].Counter.Layer;
    if devJJ[sjJ].Counter.Shape = SHAPEMCIRCLE then
      SynthMCircle(sjX, sjY, sjJJDiameterDraw/2+devJJ[sjJ].Counter.Offset, layer[devJJ[sjJ].Counter.Layer].GridSize, polys[High(polys)].Coords);
    if devJJ[sjJ].Counter.Shape = SHAPECIRCLE then
      SynthCircle(sjX, sjY, sjJJDiameterDraw/2+devJJ[sjJ].Counter.Offset, layer[devJJ[sjJ].Counter.Layer].GridSize, devJJ[sjJ].Counter.CirclePoints, polys[High(polys)].Coords);
    if devJJ[sjJ].Counter.Shape = SHAPEUNDEF then
    begin
      AddErrorString('Layer '+IntToStr(devJJ[sjJ].Counter.Layer)+' shape in '+sjDef+' not defined. Ignored.');
      SetLength(polys,Length(polys)-1);
    end;
  end
  else
  begin
    // Now build shunt resistor.
    sjMinResLength := 2*GetSurround(devJJ[sjJ].RsViaLayer, devJJ[sjJ].Counter.Layer) + GetMinSpace(devJJ[sjJ].Counter.Layer,devJJ[sjJ].Counter.Layer);
    sjMinResWidth := sjMinResLength/(GetDeviceParameter('rs',sjParams)/layer[devJJ[sjJ].RsLayer].SheetResistance);
    if sjMinResWidth < layer[devJJ[sjJ].RsLayer].MinSize then
      sjMinResWidth := layer[devJJ[sjJ].RsLayer].MinSize;

    SetLength(polys,Length(polys)+1);
    polys[High(polys)].Layer := devJJ[sjJ].RsLayer;
    sjRectangleX1 := -0.5*sjMinResWidth;
    sjRectangleX2 := +0.5*sjMinResWidth;
    sjRectangleY1 := sjJJDiameterDraw/2 + GetMinSpace(devJJ[sjJ].RsLayer, devJJ[sjJ].JJ.Layer);
    sjRectangleY2 := sjRectangleY1 + 2*GetSurround(devJJ[sjJ].RsLayer, devJJ[sjJ].RsViaLayer) + 2*layer[devJJ[sjJ].RsViaLayer].MinSize
                     + (sjMinResWidth*(GetDeviceParameter('rs',sjParams)/layer[devJJ[sjJ].RsLayer].SheetResistance));
    sjVarResY := sjRectangleY2;
    SynthRectangle(sjX, sjY, 0, 0, sjRotate, sjRectangleX1, sjRectangleY1, sjRectangleX2, sjRectangleY2, layer[devJJ[sjJ].RsLayer].GridSize, polys[High(polys)].Coords);

    // First RES via
    SetLength(polys,Length(polys)+1);
    polys[High(polys)].Layer := devJJ[sjJ].RsViaLayer;
    sjVarRsViaX := -0.5*sjMinResWidth-GetSurround(devJJ[sjJ].RsViaLayer,devJJ[sjJ].RsLayer);
    sjRectangleX1 := sjVarRsViaX;
    sjRectangleX2 := -sjVarRsViaX;
    sjRectangleY1 := sjJJDiameterDraw/2 + GetMinSpace(devJJ[sjJ].RsLayer, devJJ[sjJ].JJ.Layer) + GetSurround(devJJ[sjJ].RsLayer,devJJ[sjJ].RsViaLayer);
    sjRectangleY2 := sjRectangleY1 + layer[devJJ[sjJ].RsViaLayer].MinSize;
    sjVarRSVia1Y := sjRectangleY2;
    SynthRectangle(sjX, sjY, 0, 0, sjRotate, sjRectangleX1, sjRectangleY1, sjRectangleX2, sjRectangleY2, layer[devJJ[sjJ].RsViaLayer].GridSize, polys[High(polys)].Coords);

    // Second RES via
    SetLength(polys,Length(polys)+1);
    polys[High(polys)].Layer := devJJ[sjJ].RsViaLayer;
    sjRectangleX1 := sjVarRsViaX;
    sjRectangleX2 := -sjVarRsViaX;
    sjRectangleY1 := sjJJDiameterDraw/2 + GetMinSpace(devJJ[sjJ].RsLayer, devJJ[sjJ].JJ.Layer) + GetSurround(devJJ[sjJ].RsLayer,devJJ[sjJ].RsViaLayer)
    + layer[devJJ[sjJ].RsViaLayer].MinSize + (sjMinResWidth*(GetDeviceParameter('rs',sjParams)/layer[devJJ[sjJ].RsLayer].SheetResistance));
    sjRectangleY2 := sjRectangleY1 + layer[devJJ[sjJ].RsViaLayer].MinSize;
    sjVarRSVia2Y := sjRectangleY2;
    SynthRectangle(sjX, sjY, 0, 0, sjRotate, sjRectangleX1, sjRectangleY1, sjRectangleX2, sjRectangleY2, layer[devJJ[sjJ].RsViaLayer].GridSize, polys[High(polys)].Coords);

    // Counter-Base via
    SetLength(polys,Length(polys)+1);
    polys[High(polys)].Layer := devJJ[sjJ].CounterBaseViaLayer;
    sjRectangleX1 := -layer[devJJ[sjJ].CounterBaseViaLayer].MinSize/2;
    sjRectangleX2 := -sjRectangleX1;
    sjRectangleY1 := sjVarResY + GetMinSpace(devJJ[sjJ].RsLayer, devJJ[sjJ].CounterBaseViaLayer);
    sjRectangleY2 := sjRectangleY1 + layer[devJJ[sjJ].CounterBaseViaLayer].MinSize;
    sjVarCBViaY := sjRectangleY2;
    SynthRectangle(sjX, sjY, 0, 0, sjRotate, sjRectangleX1, sjRectangleY1, sjRectangleX2, sjRectangleY2, layer[devJJ[sjJ].CounterBaseViaLayer].GridSize, polys[High(polys)].Coords);

    // Base
    sjVarBaseX := -sjJJDiameterDraw/2 - GetSurround(devJJ[sjJ].Base.Layer, devJJ[sjJ].JJ.Layer);
    SetLength(polys,Length(polys)+1);
    polys[High(polys)].Layer := devJJ[sjJ].Base.Layer;
    sjRectangleX1 := sjVarBaseX;
    sjRectangleX2 := -sjRectangleX1;
    sjRectangleY1 := sjVarBaseX;
    sjRectangleY2 := sjVarCBViaY + GetSurround(devJJ[sjJ].Base.Layer, devJJ[sjJ].CounterBaseViaLayer);
    SynthRectangle(sjX, sjY, 0, 0, sjRotate, sjRectangleX1, sjRectangleY1, sjRectangleX2, sjRectangleY2, layer[devJJ[sjJ].CounterBaseViaLayer].GridSize, polys[High(polys)].Coords);

    // CounterJJ
    sjVarCounterX := -sjJJDiameterDraw/2 - GetSurround(devJJ[sjJ].JJViaLayer, devJJ[sjJ].Counter.Layer);
    if sjVarRsViaX - GetSurround(devJJ[sjJ].RsViaLayer, devJJ[sjJ].Counter.Layer) < sjVarCounterX then
      sjVarCounterX := sjVarRsViaX - GetSurround(devJJ[sjJ].RsViaLayer, devJJ[sjJ].Counter.Layer);
    SetLength(polys,Length(polys)+1);
    polys[High(polys)].Layer := devJJ[sjJ].Counter.Layer;
    sjRectangleX1 := sjVarCounterX;
    sjRectangleX2 := -sjRectangleX1;
    sjRectangleY1 := sjVarCounterX;
    sjRectangleY2 := sjVarRSVia1Y + GetSurround(devJJ[sjJ].CounterBaseViaLayer, devJJ[sjJ].Counter.Layer);
    SynthRectangle(sjX, sjY, 0, 0, sjRotate, sjRectangleX1, sjRectangleY1, sjRectangleX2, sjRectangleY2, layer[devJJ[sjJ].CounterBaseViaLayer].GridSize, polys[High(polys)].Coords);

    // Counter RES-to-BASE
    sjVarCounter2X := sjVarRsViaX - GetSurround(devJJ[sjJ].RsViaLayer, devJJ[sjJ].Counter.Layer);
    if (-layer[devJJ[sjJ].CounterBaseViaLayer].MinSize/2 - GetSurround(devJJ[sjJ].CounterBaseViaLayer, devJJ[sjJ].Counter.Layer)) < sjVarCounter2X then
      sjVarCounter2X := (-layer[devJJ[sjJ].CounterBaseViaLayer].MinSize/2 - GetSurround(devJJ[sjJ].CounterBaseViaLayer, devJJ[sjJ].Counter.Layer));
    SetLength(polys,Length(polys)+1);
    polys[High(polys)].Layer := devJJ[sjJ].Counter.Layer;
    sjRectangleX1 := sjVarCounter2X;
    sjRectangleX2 := -sjRectangleX1;
    sjRectangleY1 := sjVarRSVia2Y - layer[devJJ[sjJ].RsViaLayer].MinSize - GetSurround(devJJ[sjJ].CounterBaseViaLayer, devJJ[sjJ].Counter.Layer);
    sjRectangleY2 := sjVarCBViaY + GetSurround(devJJ[sjJ].CounterBaseViaLayer, devJJ[sjJ].Counter.Layer);
    SynthRectangle(sjX, sjY, 0, 0, sjRotate, sjRectangleX1, sjRectangleY1, sjRectangleX2, sjRectangleY2, layer[devJJ[sjJ].CounterBaseViaLayer].GridSize, polys[High(polys)].Coords);

    if devJJ[sjJ].IsGrounded then
    begin
      // Include ground contact
      sjVarLowerGndViaY := sjJJDiameterDraw/2 + GetMinSpace(devJJ[sjJ].LowerGndViaLayer, devJJ[sjJ].JJ.Layer);
      SetLength(polys,Length(polys)+1);
      polys[High(polys)].Layer := devJJ[sjJ].LowerGndViaLayer;
      sjRectangleX1 := -((layer[devJJ[sjJ].LowerGndViaLayer].MinSize+layer[devJJ[sjJ].LowerGndViaLayer].MaxSize)/2)/2;
      sjRectangleX2 := -sjRectangleX1;
      sjRectangleY1 := sjVarLowerGndViaY;
      sjRectangleY2 := sjVarLowerGndViaY + (layer[devJJ[sjJ].LowerGndViaLayer].MinSize+layer[devJJ[sjJ].LowerGndViaLayer].MaxSize)/2;
      SynthRectangle(sjX, sjY, 0, 0, sjRotate, sjRectangleX1, sjRectangleY1, sjRectangleX2, sjRectangleY2, layer[devJJ[sjJ].LowerGndViaLayer].GridSize, polys[High(polys)].Coords);
    end;
    

  end;



  if verboseOn then EchoLn('Synthesized JJ "'+sjDef+'" at ('+FloatToStrF(sjX,ffGeneral,4,2)+', '+FloatToStrF(sjY,ffGeneral,4,2)+').');

end; // SynthJJ


end.
