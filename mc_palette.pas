unit mc_palette;

{$mode objfpc}{$H+}
{$ModeSwitch advancedrecords}

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
    public
        function GetValue_Raw(BlockRecord:TMC_PaletteRecord):TMC_Block;
        function GetValue_Colorize(BlockRecord:TMC_PaletteRecord):TMC_Block;
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
        function FindBlockBySectionId(SectionId:integer):PMC_PaletteRecord;
    public
        constructor Create;
        destructor Destroy; override;
    end;

implementation

function TMC_PaletteRecord.GetValue_Raw(BlockRecord:TMC_PaletteRecord):TMC_Block;
begin
    result:=TMC_Block((DWord(BlockRecord.id) shl 16) or (BlockRecord.data shl 8));
end;

function TMC_PaletteRecord.GetValue_Colorize(BlockRecord:TMC_PaletteRecord):TMC_Block;
begin
    result:=TMC_Block(BlockRecord.color);
end;

function TMC_Palette.FindBlock(BlockName:string):PMC_PaletteRecord;
begin

end;

procedure TMC_Palette.AddBlock(BlockName:string; BlockId:integer=-1; BlockData:byte=255; BlockColor:TColor=clBlack);
begin

end;

procedure TMC_Palette.ClearSectionPatette;
begin
    SetLength(FSection,0);
end;

procedure TMC_Palette.AppendSectionPatette(BlockName:string);
begin

end;

function TMC_Palette.FindBlockBySectionId(SectionId:integer):PMC_PaletteRecord;
begin

end;

constructor TMC_Palette.Create;
begin
    FUniverse := TStringList.Create;
    SetLength(FSection,0);
end;

destructor TMC_Palette.Destroy;
begin
    FUniverse.Free;
    SetLength(FSection,0);
end;

end.

