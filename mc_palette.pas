unit mc_palette;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, Graphics;

type

    TMC_Block = record case integer of
        0:(vDWord:dword); //RGBa = add blk dat nul
        1:(vBands:array[0..3]of byte);
        2:(
           vBlock:word;
           vData:byte;
           vNull:byte
           );
    end;

    TMC_PaletteRecord = packed record
        id       : Integer;
        data     : byte;
        rejected : boolean;
        color    : TColor;
    end;
    PMC_PaletteRecord = ^TMC_PaletteRecord;

    //Universal Block Palette
    TMC_Palette = class
        FUniverse : TStringList;
        FSection  : array of Integer;
    public
        function FindBlock(BlockName:string):PMC_PaletteRecord;
        procedure AddBlock(BlockName:string; BlockId:integer=-1; BlockData:byte=255; BlockColor:TColor=clBlack);
        procedure ClearSectionPatette;
        procedure AppendSectionPatette(BlockName:string);
        function SectionIdToUniverseId(SectionId:integer):TMC_Block;
    end;

implementation

function TMC_Palette.FindBlock(BlockName:string):PMC_PaletteRecord;
begin

end;

procedure TMC_Palette.AddBlock(BlockName:string; BlockId:integer=-1; BlockData:byte=255; BlockColor:TColor=clBlack);
begin

end;

procedure TMC_Palette.ClearSectionPatette;
begin

end;

procedure TMC_Palette.AppendSectionPatette(BlockName:string);
begin

end;

function TMC_Palette.SectionIdToUniverseId(SectionId:integer):TMC_Block;
begin

end;




end.

