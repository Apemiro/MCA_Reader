unit blocks_definition;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

  TBlockList = class(TObject)
    FBlockList:TStringList;
  public
    procedure LoadFromFile(filename:string);
    procedure SaveToFile(filename:string);
    function ExportToString(Delimiter:string=','):string;
    function FindBlockId(block_name:string):Integer;
    function AddBlockId(block_name:string):Integer;
  public
    constructor Create;
    destructor Destroy;override;
  end;//储存名称与ID关系

  TBiomeList=TBlockList;

  TBlockUnit=class
    name:string;
    id:word;
    data:packed record case integer of
      0:(
        rotation:byte;
        attachment:byte;
        level:byte;
        lit:boolean
      );
      1:(data:byte);
    end;
  public
    function to_csv_line:string;
  end;//详细的方块索引信息

  TBlockPalette = class(TList)
  public
    function RegisterBlock(block_name:string):Integer;
    procedure SaveToCSV(filename:string);
  public
    constructor Create;
    destructor Destroy;override;
  end;//方块索引列表

var defaultBlocks:TBlockList;
    defaultBiomes:TBiomeList;


implementation

procedure TBlockList.LoadFromFile(filename:string);
begin
  Self.FBlockList.LoadFromFile(filename);
end;
procedure TBlockList.SaveToFile(filename:string);
begin
  Self.FBlockList.SaveToFile(filename);
end;
function TBlockList.ExportToString(Delimiter:string=','):string;
var stmp:string;
    itmp,dlen:integer;
begin
  result:='';
  itmp:=0;
  for stmp in Self.FBlockList do begin
    result:=result+IntToStr(itmp)+': "'+stmp+'"'+Delimiter;
    inc(itmp);
  end;
  dlen:=length(Delimiter);
  if itmp>0 then System.Delete(result,length(result)-dlen+1,dlen);
end;

function TBlockList.FindBlockId(block_name:string):Integer;
var pi:integer;
begin
    pi:=0;
    while pi<Self.FBlockList.Count do begin
        if Self.FBlockList[pi]=block_name then begin
            result:=pi;
            exit;
        end;
        inc(pi);
    end;
    result:=-1;
end;

function TBlockList.AddBlockId(block_name:string):Integer;
begin
  result:=FindBlockId(block_name);
  if result>=0 then exit;
  result:=FBlockList.Count;
  Self.FBlockList.AddText(block_name);
end;

constructor TBlockList.Create;
begin
  inherited Create;
  Self.FBlockList:=TStringList.Create;
end;

destructor TBlockList.Destroy;
begin
  Self.FBlockList.Free;
  inherited Destroy;
end;



function TBlockUnit.to_csv_line:string;
begin
  result:=Self.name+','+IntToStr(Self.id)+','+IntToStr(Self.data.data);
end;

function TBlockPalette.RegisterBlock(block_name:string):Integer;
var tmp:TBlockUnit;
    pi:integer;
begin
  if Self.Count<>0 then begin
    pi:=0;
    while pi<Self.count do
      begin
        if TBlockUnit(Self.Items[pi]).name=block_name then
          begin
            result:=pi;
            exit;
          end;
        inc(pi);
      end;
  end;
  tmp:=TBlockUnit.Create;
  tmp.name:=block_name;
  Self.Add(tmp);
  result:=Self.Count-1;
end;

procedure TBlockPalette.SaveToCSV(filename:string);
var tmp:text;
    pi:integer;
    blk:TBlockUnit;
begin
  try
    assignfile(tmp,filename);
    rewrite(tmp);
    writeln(tmp,'name,id,data');
    for pi:=0 to Self.Count-1 do
      begin
        blk:=TBlockUnit(Self.Items[pi]);
        writeln(tmp,blk.to_csv_line);
      end;
    closefile(tmp);
  except
  end;
end;

constructor TBlockPalette.Create;
begin
  inherited Create;
end;

destructor TBlockPalette.Destroy;
begin
  while Self.Count<>0 do
    begin
      TBlockUnit(Self.Items[0]).Free;
      Self.Delete(0);
    end;
  inherited Destroy;
end;


initialization

  defaultBlocks:=TBlockList.Create;
  defaultBiomes:=TBiomeList.Create;
  {
  try
    defaultBlocks.LoadFromFile('defaultBlocks.txt');
  finally
    //defaultBlocks.AddBlockId('minecraft:air');
    //defaultBlocks.AddBlockId('minecraft:stone');
    //defaultBlocks.AddBlockId('minecraft:grass');
    //defaultBlocks.AddBlockId('minecraft:dirt');
    //defaultBlocks.AddBlockId('minecraft:cobblestone');
    //defaultBlocks.AddBlockId('minecraft:planks');
    //defaultBlocks.AddBlockId('minecraft:sapling');
    //defaultBlocks.AddBlockId('minecraft:bedrock');
    //defaultBlocks.AddBlockId('minecraft:water_source');
    //defaultBlocks.AddBlockId('minecraft:water_still');
    //defaultBlocks.AddBlockId('minecraft:lava_source');
    //defaultBlocks.AddBlockId('minecraft:lava_still');
    //defaultBlocks.AddBlockId('minecraft:sand');
    //defaultBlocks.AddBlockId('minecraft:gravel');

  end;
  }
finalization
  //defaultBlocks.SaveToFile('defaultBlocks.txt');
  defaultBlocks.Free;
  defaultBiomes.Free;
end.

