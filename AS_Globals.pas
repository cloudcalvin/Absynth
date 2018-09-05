unit AS_Globals;

{
    Unit AS_Globals (for use with Absynth)
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

{$IFDEF Unix}
{$mode objfpc}{$H+}
{$ENDIF Unix}

interface

//type
  {enumerated types, alphabetically}

type
  {enumerated types, alphabetically}
  TLayerTypes = (JJ,RES,SC,LAYERUNDEF,VIA);
  TDeviceTypes = (DEVICEJJ,DEVICEUNDEF);
  TDevShapes = (SHAPECIRCLE,SHAPEMCIRCLE,SHAPEUNDEF);

const
  VERSIONNUMBER = '0.01.03';
  COPYRIGHTNOTICE = 'Copyright 2017 Coenrad Fourie';
  BUILDDATE = '30 Nov 2017';

  DEFAULTPROCESSJC = 100e-6;   // in A/um2
  DEFAULTDRAWUNITSPERLENGTHUNIT = 1000.0;
  MAXGDSLAYERS = 256;
  UNITSIZEINMETRES = 1e-6;

type
  Str1 = string[1];
  Str2 = string[2];
  Str8 = string[8];
  Str20 = string[20];
  Str79 = string[79];
  TWarningStringArray = array of str79;
  TIntegerCoordinatesXY = record
    x, y : integer
  end;
  TRealCoordinatesXY = record
    x, y : double;
  end;
  TASPolyCoords = array of TIntegerCoordinatesXY;
  TASPolyCoordsReal = array of TRealCoordinatesXY;
  TASPolyRecord = record
    Coords : TASPolyCoords;
    Layer : integer;
  end;
  TASPoly = array of TASPolyRecord;
  TParamVariable = record
    Name : Str79;
    Value : Double;
  end;
  TDevice = record
    Name : Str79;
    Typ : TDeviceTypes;
  end;
  TDevParams = record
    Name : Str79;
    Value : double;
  end;
  TDevParamArray = array of TDevParams;
  TDevObject = record
    Layer, CirclePoints : integer;
    Shape : TDevShapes;
    Offset : double;
  end;
  TDeviceJJ = record
    Name : Str79;
    Parameters : TDevParamArray;
    Base, Counter, JJ : TDevObject;
    Objects : array of TDevObject;
    RsLayer, RsViaLayer, JJViaLayer, CounterBaseViaLayer, LowerGndLayer, LowerGndViaLayer : integer;
    IsGrounded : boolean;
  end;
  TLayerRule = record
    Layer : integer;
    Value : double;
  end;
  TLayerRuleArray = array of TLayerRule;
  TLayer = record
    Number : integer;
    Name : Str20;
    Typ : TLayerTypes;
    Jc, Dc, B, GridSize, MinSize, MaxSize, MaxWidth, SheetResistance : double;
    MinSpace, Surround : TLayerRuleArray;
  end;
  TDoubleArray = array of double;


var
  absFileParam, gdsOutFileParam, processFileParam : Integer;
  absFileName, gdsOutFileName, processFileName, structName : String;
  libName : Str8;
  unitSize : Double;  // Unit Size in metres
  outFile : TextFile;
  dxfFile : TextFile;
  gdsOutFile : file of byte;
  warningStrings, errorStrings : TWarningStringArray;
  polys : TASPoly;
  drawScaleInt : integer;
  drawScale : double;  // Number of smallest drawing steps in unit
  paramVariable : array of TParamVariable;
  layer : array[0..MAXGDSLAYERS] of TLayer;
  device : array of TDevice;
  devJJ : array of TDeviceJJ;
  verboseOn : boolean;
implementation

end.

