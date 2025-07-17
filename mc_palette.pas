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

    TMC_PaletteRecord = record
        id       : Integer;
        data     : byte;//这是兼容1.13之前的版本，在色板模式中实际上不会使用
        rejected : boolean;
        color    : TColor;
    public
        function GetValue_Raw:TMC_Block;
        function GetValue_Colorize:TMC_Block;
    end;
    PMC_PaletteRecord = ^TMC_PaletteRecord;

    //Universal Block Palette
    TMC_Palette = class
        FUniverse  : TStringList;
        FRejection : TStringList;
        FSectionSet: TStringList;
        FSection   : array of PMC_PaletteRecord;
        FBlockList : array of PMC_PaletteRecord;
        FReverseRejection : Boolean;
    protected
        function GetBlockItem(index:integer):PMC_PaletteRecord;
        function GetBlockListSize:integer;
        function GetSectionsSize:integer;

    public
        procedure AddBlockRejection(BlockName:string);
        procedure ClearBlockRejection;
        function FindBlock(BlockName:string):PMC_PaletteRecord;
        function AddBlock(BlockName:string;BlockColor:TColor=clBlack):PMC_PaletteRecord;
        procedure ClearSectionPatette;
        procedure AppendSectionPatette(BlockName:string);
        function FindBlockBySectionId(SectionId:integer):PMC_PaletteRecord;
        property ReverseRejection:Boolean read FReverseRejection write FReverseRejection;
        property BlockItems[index:integer]:PMC_PaletteRecord read GetBlockItem;
        property BlockListSize:integer read GetBlockListSize;
        property SectionsSize:integer read GetSectionsSize;
    public
        constructor Create;
        destructor Destroy; override;
    end;

implementation

function TMC_PaletteRecord.GetValue_Raw:TMC_Block;
begin
    result:=TMC_Block((DWord(id) shl 16) or (data shl 8));
end;

function TMC_PaletteRecord.GetValue_Colorize:TMC_Block;
begin
    result:=TMC_Block(color);
end;

function TMC_Palette.GetBlockItem(index:integer):PMC_PaletteRecord;
begin
    result:=nil;
    if index>=Length(FBlockList) then exit;
    result:=PMC_PaletteRecord(FBlockList[index]);
end;

function TMC_Palette.GetBlockListSize:integer;
begin
    result:=Length(FBlockList);
end;

function TMC_Palette.GetSectionsSize:integer;
begin
    result:=Length(FSection);
end;

procedure TMC_Palette.AddBlockRejection(BlockName:string);
begin
    FRejection.Add(BlockName);
end;

procedure TMC_Palette.ClearBlockRejection;
begin
    FRejection.Clear;
end;

function TMC_Palette.FindBlock(BlockName:string):PMC_PaletteRecord;
var index:integer;
begin
    if FUniverse.Find(BlockName, index) then
        result:=PMC_PaletteRecord(FUniverse.Objects[index])
    else
        result:=nil;
end;

function TMC_Palette.AddBlock(BlockName:string;BlockColor:TColor=clBlack):PMC_PaletteRecord;
var pPR:PMC_PaletteRecord;
    idx,len:integer;
begin
    result:=FindBlock(BlockName);
    if result<>nil then exit;
    pPR:=GetMem(SizeOf(PMC_PaletteRecord));
    with pPR^ do begin
        id       := FUniverse.Count;
        data     := 255;
        color    := BlockColor;
        rejected := FRejection.Find(BlockName, idx);
    end;
    FUniverse.AddObject(BlockName,TObject(pPR));
    len:=Length(FBlockList);
    SetLength(FBlockList,len+1);
    FBlockList[len]:=pPR;
    result:=pPR;
end;

procedure TMC_Palette.ClearSectionPatette;
begin
    SetLength(FSection,0);
    FSectionSet.Clear;
end;

procedure TMC_Palette.AppendSectionPatette(BlockName:string);
var len,idx:integer;
    pPR:PMC_PaletteRecord;
begin
    pPR:=FindBlock(BlockName);
    if pPR=nil then
        raise Exception.Create('TMC_Palette.AppendSectionPatette cannot find block record.');
    len:=Length(FSection);
    SetLength(FSection,len+1);
    FSection[len]:=pPR;
    FSectionSet.Add(BlockName);
end;

function TMC_Palette.FindBlockBySectionId(SectionId:integer):PMC_PaletteRecord;
var idx,len:integer;
begin
    len:=Length(FSection);
    if SectionId>=len then begin
        writeln(SectionId, ' / ',len);
        for idx:=0 to len-1 do writeln(FSection[idx]^.id);
        raise Exception.Create('TMC_Palette.FindBlockBySectionId cannot match the section ID.');
    end;
    result:=FSection[SectionId];
end;

constructor TMC_Palette.Create;
begin
    FUniverse:=TStringList.Create;
    FUniverse.Sorted:=true;
    FRejection:=TStringList.Create;
    FRejection.Sorted:=true;
    FSectionSet:=TStringList.Create;
    FSectionSet.Sorted:=true;
    FReverseRejection:=false;
    SetLength(FSection,0);
    SetLength(FBlockList,0);

end;

destructor TMC_Palette.Destroy;
var index:integer;
begin
    for index:=Length(FSection)-1 downto 0 do
        FreeMem(PMC_PaletteRecord(FUniverse.Objects[index]),SizeOf(PMC_PaletteRecord));
    FUniverse.Free;
    FRejection.Free;
    FSectionSet.Free;
    SetLength(FSection,0);
    SetLength(FBlockList,0);

end;

end.

