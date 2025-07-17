unit mca_tile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, color_rule, mca_base, selection_rule, mc_palette;

type

  TMCPoint=record
    x,z:integer;
  end;


  TMCA_Tile=class
  private
    FBitMap:TBitMap;
    FPosition:TMCPoint;//MCA块的编号，与r.x.z.mca相同
    FOffset:TMCPoint;//Get*方法时需要设置的相对区块位置
  protected
    procedure SetBlockId(x,z:integer;id:word);
    procedure SetBlockData(x,z:integer;data:byte);
    function GetBlockId(x,z:integer):word;
    function GetBlockData(x,z:integer):byte;
  public
    property BlockId[x,z:integer]:word read GetBlockId write SetBlockId;
    property BlockData[x,z:integer]:byte read GetBlockData write SetBlockData;
    property Position:TMCPoint read FPosition write FPosition;
    property Offset:TMCPoint read FOffset write FOffset;
    procedure SetOffset(x,z:integer);
  public
    procedure GetBiomesClip(block:TChunk_Block;y:integer);
    procedure GetClip(block:TChunk_Block;y:integer);
    procedure GetSurface(block:TChunk_Block;mode:string='ws');
    procedure GetHeight(block:TChunk_Block;mode:string='ws');//通过高度图获得
    procedure GetRealHeight(block:TChunk_Block;palette:TMC_Palette=nil);//通过搜索获得
    procedure GetBelow(block:TChunk_Block;y:integer;palette:TMC_Palette);
    procedure GetAbove(block:TChunk_Block;y:integer;palette:TMC_Palette);
    procedure GetDensity(block:TChunk_Block;palette:TMC_Palette);

  public
    procedure Colorize_Raw;//按照256R+G:B底片格式赋值FBitMap
    procedure Colorize_Fix;//全给我涂色
    procedure Colorize_Exaggerated;//按照夸张格式赋值FBitMap
    procedure Colorize_Rule(ColorRule:TColorRule);//按照颜色文件赋值FBitMap


  public
    constructor create(x,z:integer);
    destructor Destroy;override;
  end;

  TMCA_Tile_List=class(TList)
  protected
    function GetTile(x,z:integer):TMCA_Tile;
  public
    property Tile[x,z:integer]:TMCA_Tile read GetTile;
  public
    //procedure GetChunkPlan(blocks:TChunk_Block;mode:string;param1:integer=0;param2:integer=0;param3:TObject=nil);deprecated;//mode=clip,below,above,height,density...
    procedure Projection(blocks:TChunk_Block; mode:string; floor:integer=0; palette:TMC_Palette=nil);

  public
    procedure SaveToFile(filename:string);
    procedure SaveAsTiff(filename_without_ext:string);
    procedure Colorize(mode:string;ColorRule:TColorRule=nil);
  public
    class function AufTypeName:String;
  end;

implementation
uses apiglio_tree;

procedure TMCA_Tile.SetBlockId(x,z:integer;id:word);
begin
  pword(Self.FBitMap.ScanLine[0]+4*(x+z*512))^:=id;
end;
procedure TMCA_Tile.SetBlockData(x,z:integer;data:byte);
begin
  pbyte(Self.FBitMap.ScanLine[0]+4*(x+z*512)+2)^:=data;
end;
function TMCA_Tile.GetBlockId(x,z:integer):word;
begin
  result:=pword(Self.FBitMap.ScanLine[0]+4*(x+z*512))^;
end;
function TMCA_Tile.GetBlockData(x,z:integer):byte;
begin
  result:=pbyte(Self.FBitMap.ScanLine[0]+4*(x+z*512)+2)^;
end;

procedure TMCA_Tile.SetOffset(x,z:integer);
begin
  Self.FOffset.x:=x;
  Self.FOffset.z:=z;
end;

procedure TMCA_Tile.GetBiomesClip(block:TChunk_Block;y:integer);
var x,z:byte;
    adapter:dword;
    pStream:TMemoryStream;
begin
    if y>=0 then begin
        pStream:=block.Biomes;
        pStream.Position:=y*256*4;
    end else begin
        pStream:=block.BiomesBelow;
        pStream.Position:=-((y+1) div 16) shl 14 + (y+17) mod 16 shl 10;
    end;
    z:=0;
    x:=0;
    while z<16 do begin
        adapter:=pStream.ReadDWord;
        pdword(Self.FBitMap.ScanLine[z+Offset.z]+4*(x+Offset.x))^:=adapter;
        inc(x);
        if x=16 then begin
            x:=0;
            inc(z);
        end;
    end;
end;

procedure TMCA_Tile.GetClip(block:TChunk_Block;y:integer);
var x,z:byte;
    adapter:dword;
    pStream:TMemoryStream;
begin
    if y>=0 then begin
        pStream:=block.Stream;
        pStream.Position:=y*256*4;
    end else begin
        pStream:=block.SBelow;
        pStream.Position:=-((y+1) div 16) shl 14 + (y+17) mod 16 shl 10;
        //pStream.Position:=4096*4*-((y+1) div 16) + 256*4*((y+1) mod 16);
    end;
    z:=0;
    x:=0;
    while z<16 do begin
        adapter:=pStream.ReadDWord;
        pdword(Self.FBitMap.ScanLine[z+Offset.z]+4*(x+Offset.x))^:=adapter;
        inc(x);
        if x=16 then begin
            x:=0;
            inc(z);
        end;
    end;
end;
procedure TMCA_Tile.GetSurface(block:TChunk_Block;mode:string='ws');
var x,z:byte;
    y,tmp:word;
    adapter:dword;
    HeightMap:pword;
begin
  case lowercase(mode) of
    'mb':if block.MB_Enable=0 then exit else HeightMap:=pword(@(block.MB_Enable))-256;
    'mbn':if block.MBN_Enable=0 then exit else HeightMap:=pword(@(block.MBN_Enable))-256;
    'of':if block.OF_Enable=0 then exit else HeightMap:=pword(@(block.OF_Enable))-256;
    'ofw':if block.OFW_Enable=0 then exit else HeightMap:=pword(@(block.OFW_Enable))-256;
    'ws':if block.WS_Enable=0 then exit else HeightMap:=pword(@(block.WS_Enable))-256;
    'wsw':if block.WSW_Enable=0 then exit else HeightMap:=pword(@(block.WSW_Enable))-256;
    else assert(false,'错误的GetSurface模式。');
  end;
  //block.Stream.position:=y*256*4;
  z:=0;x:=0;
  while z<16 do
    begin
      tmp:=16*z+x;
      y:=(HeightMap+tmp)^;
      if y<>0 then begin
        block.Stream.Position:=4*((y-1)*256+tmp);
        adapter:=block.Stream.ReadDWord;
        pdword(Self.FBitMap.ScanLine[z+Offset.z]+4*(x+Offset.x))^:=adapter;
      end;
      inc(x);
      if x=16 then
        begin
          x:=0;inc(z);
        end;
    end;
end;
procedure TMCA_Tile.GetDensity(block:TChunk_Block;palette:TMC_Palette);
var x,z:byte;
    yy,min_y,max_y:integer;
    adapter:TMC_Block;
    den:integer;
    pPR:PMC_PaletteRecord;
begin
    z := 0;
    x := 0;
    min_y := -(block.SBelow.Size div 1024);
    max_y :=   block.Stream.Size div 1024;
    while z<16 do begin
        den:=0;
        for yy:=max_y-1 downto min_y do begin
            if yy>=0 then begin
                block.Stream.position:=(yy*256+z*16+x)*4;
                adapter.vDWord:=block.Stream.ReadDWord;
            end else begin
                block.SBelow.position:=-((yy+1) div 16) shl 14 + ((yy+16) mod 16) shl 10 + (z*16+x)*4;
                adapter.vDWord:=block.SBelow.ReadDWord;
            end;
            if palette<>nil then begin
                pPR:=palette.BlockItems[adapter.vBlock];
                if not pPR^.rejected xor palette.ReverseRejection then
                    inc(den);
            end;
        end;
        pdword(Self.FBitMap.ScanLine[z+Offset.z]+4*(x+Offset.x))^:=den shl 8; //RGBa
        inc(x);
        if x=16 then begin
            x:=0;
            inc(z);
        end;
    end;
end;
procedure TMCA_Tile.GetRealHeight(block:TChunk_Block;palette:TMC_Palette);
var x,z,yy:byte;
    adapter:dword;
begin
  z:=0;x:=0;
  while z<16 do
    begin
      yy:=255;
      repeat
        block.Stream.position:=(yy*256+z*16+x)*4;
        adapter:=block.Stream.ReadDWord;
        //if sel<>nil then case sel_mode of
        //  smExclude: adapter:=sel.ExcludeSelection[adapter];
        //  smJust:    adapter:=sel.JustSelection[adapter];
        //end;
        pdword(Self.FBitMap.ScanLine[z+Offset.z]+4*(x+Offset.x))^:=yy shl 24;
        dec(yy);
      until (adapter and $00ffffff<>0) or (yy=255);
      inc(x);
      if x=16 then
        begin
          x:=0;inc(z);
        end;
    end;
end;
procedure TMCA_Tile.GetHeight(block:TChunk_Block;mode:string='ws');
var x,z:byte;
    y,tmp:word;
    HeightMap:pword;
begin
  case lowercase(mode) of
    'mb':if block.MB_Enable=0 then exit else HeightMap:=pword(@(block.MB_Enable))-256;
    'mbn':if block.MBN_Enable=0 then exit else HeightMap:=pword(@(block.MBN_Enable))-256;
    'of':if block.OF_Enable=0 then exit else HeightMap:=pword(@(block.OF_Enable))-256;
    'ofw':if block.OFW_Enable=0 then exit else HeightMap:=pword(@(block.OFW_Enable))-256;
    'ws':if block.WS_Enable=0 then exit else HeightMap:=pword(@(block.WS_Enable))-256;
    'wsw':if block.WSW_Enable=0 then exit else HeightMap:=pword(@(block.WSW_Enable))-256;
    else GetRealHeight(block);
  end;
  //block.Stream.position:=y*256*4;
  z:=0;x:=0;
  while z<16 do
    begin
      tmp:=16*z+x;
      y:=(HeightMap+tmp)^;
      if y>0 then dec(y);
      pdword(Self.FBitMap.ScanLine[z+Offset.z]+4*(x+Offset.x))^:=y shl 24;
      inc(x);
      if x=16 then
        begin
          x:=0;inc(z);
        end;
    end;
end;
procedure TMCA_Tile.GetBelow(block:TChunk_Block;y:integer;palette:TMC_Palette);
var x,z:byte;
    yy,min_y:integer;
    adapter:TMC_Block;
    pPR:PMC_PaletteRecord;
begin
    min_y:=-block.SBelow.Size div (256*4);
    z:=0;
    x:=0;
    while z<16 do begin
        yy:=y;
        repeat
            if yy>=0 then begin
                block.Stream.position:=(yy*256+z*16+x)*4;
                adapter.vDWord:=block.Stream.ReadDWord;
            end else begin
                block.SBelow.position:=-((yy+1) div 16) shl 14 + ((yy+16) mod 16) shl 10 + (z*16+x)*4;
                adapter.vDWord:=block.SBelow.ReadDWord;
            end;
            adapter.vData:=z;
            adapter.vNull:=z;
            if palette<>nil then begin
                pPR:=palette.BlockItems[adapter.vBlock];
                if pPR<>nil then
                    if not pPR^.rejected xor palette.ReverseRejection then begin
                        pdword(Self.FBitMap.ScanLine[z+Offset.z]+4*(x+Offset.x))^:=adapter.vDWord;
                        //write(' ',IntToHex(adapter.vDWord,8));
                        break;
                    end;
            end;
            dec(yy);
        until yy=min_y;
        inc(x);
        if x=16 then begin
            x:=0;
            inc(z);
        end;
    end;
end;
procedure TMCA_Tile.GetAbove(block:TChunk_Block;y:integer;palette:TMC_Palette);
var x,z:byte;
    yy,max_y:integer;
    adapter:TMC_Block;
    pPR:PMC_PaletteRecord;
begin
    max_y:=block.Stream.Size div (256*4) - 1;
    z:=0;
    x:=0;
    while z<16 do begin
        yy:=y;
        repeat
            if yy>=0 then begin
                block.Stream.position:=(yy*256+z*16+x)*4;
                adapter.vDWord:=block.Stream.ReadDWord;
            end else begin
                block.SBelow.position:=-((yy+1) div 16) shl 14 + ((yy+16) mod 16) shl 10 + (z*16+x)*4;
                adapter.vDWord:=block.SBelow.ReadDWord;
            end;
            if palette<>nil then begin
                pPR:=palette.BlockItems[adapter.vBlock];
                if pPR<>nil then
                    if not pPR^.rejected xor palette.ReverseRejection then begin
                        pdword(Self.FBitMap.ScanLine[z+Offset.z]+4*(x+Offset.x))^:=adapter.vDWord;
                        break;
                    end;
            end;
            inc(yy);
        until yy=max_y;
        inc(x);
        if x=16 then begin
            x:=0;
            inc(z);
        end;
    end;
end;


procedure TMCA_Tile.Colorize_Raw;
var BlockIndex:longint;
    fsour,bitmp:pbyte;
    x,z:integer;
begin
  {
  for BlockIndex:=0 to 512*512-1 do
    begin

      x:=blockIndex mod 512;
      z:=BlockIndex div 512;
      bitmp:=pbyte(FBitMap.ScanLine[z] + 4*x);
      (bitmp+3)^:=$00;
      (bitmp+2)^:=Self.BlockData[x,z];
      (bitmp+1)^:=Self.BlockId[x,z] mod 256;
      (bitmp+0)^:=Self.BlockId[x,z] div 256;

    end;
  }
end;

procedure TMCA_Tile.Colorize_Fix;
var BlockIndex:longint;
    fsour,bitmp:pbyte;
    x,z:integer;
begin
  for BlockIndex:=0 to 512*512-1 do
    begin
      x:=blockIndex mod 512;
      z:=BlockIndex div 512;
      bitmp:=pbyte(FBitMap.ScanLine[z] + 4*x);
      (bitmp+3)^:=$ff;
      (bitmp+2)^:=$44;
      (bitmp+1)^:=$88;
      (bitmp+0)^:=$BB;
    end;
end;

procedure TMCA_Tile.Colorize_Exaggerated;
var BlockIndex:longint;
    fsour,bitmp:pbyte;
    x,z:integer;
begin
  for BlockIndex:=0 to 512*512-1 do
    begin
      x:=blockIndex mod 512;
      z:=BlockIndex div 512;
      bitmp:=pbyte(FBitMap.ScanLine[z] + 4*x);
      (bitmp+2)^:=16*Self.BlockData[x,z];
      (bitmp+1)^:=16*(Self.BlockId[x,z] mod 16);
      (bitmp+0)^:=16*(Self.BlockId[x,z] div 256 mod 16);
    end;
end;

procedure TMCA_Tile.Colorize_Rule(ColorRule:TColorRule);
var BlockIndex:longint;
    fsour,bitmp:pbyte;
    x,z:integer;
    pixel:TColor;
begin
  if ColorRule=nil then begin Colorize_Raw;exit end;
  for BlockIndex:=0 to 512*512-1 do
    begin
      x:=blockIndex mod 512;
      z:=BlockIndex div 512;
      bitmp:=pbyte(FBitMap.ScanLine[z] + 4*x);
      pixel:=ColorRule.BlockColor[Self.BlockId[x,z],Self.BlockData[x,z]];
      (bitmp+0)^:=(pixel shr 16) mod 256;
      (bitmp+1)^:=(pixel mod 63336) shr 8;
      (bitmp+2)^:=pixel mod 256
    end;
end;


constructor TMCA_Tile.create(x,z:integer);
begin
  inherited Create;
  FBitMap:=TBitMap.Create;
  FBitMap.PixelFormat:=pf32bit;
  FBitMap.SetSize(512,512);
  Self.FPosition.x:=x;
  Self.FPosition.z:=z;
  //Self.FBlockId:=TMemoryStream.Create;
  //Self.FBlockId.Size:=512*512*2;
  //Self.FBlockId.Position:=0;
  //while Self.FBlockId.Position<Self.FBlockId.Size do Self.FBlockId.WriteQWord(0);
  //Self.FBlockData:=TMemoryStream.Create;
  //Self.FBlockData.Size:=512*512;
  //Self.FBlockData.Position:=0;
  //while Self.FBlockData.Position<Self.FBlockData.Size do Self.FBlockData.WriteQWord(0);

end;

destructor TMCA_Tile.Destroy;
begin
  //Self.FBlockId.Free;
  //Self.FBlockData.Free;
  FBitMap.Free;
  inherited Destroy;
end;



function TMCA_Tile_List.GetTile(x,z:integer):TMCA_Tile;
var pi:integer;
    tmp_tile:TMCA_Tile;
begin
  result:=nil;
  pi:=0;
  while pi<Self.Count do
    begin
      tmp_tile:=TMCA_Tile(Self.items[pi]);
      if (tmp_tile.Position.x=x) and (tmp_tile.Position.z=z) then
        begin
          result:=tmp_tile;
          break
        end;
      inc(pi);
    end;
  if result<>nil then exit;
  result:=TMCA_Tile.create(x,z);
  Self.Add(result);
end;

{
procedure TMCA_Tile_List.GetChunkPlan(blocks:TChunk_Block;mode:string;param1:integer=0;param2:integer=0;param3:TObject=nil);
var mca_x,mca_z,ofs_x,ofs_z:longint;
    tmp_tile:TMCA_Tile;
begin
  mca_x:=0;
  mca_z:=0;
  ofs_x:=blocks.x;
  ofs_z:=blocks.z;
  while ofs_x<0 do begin inc(ofs_x,32);dec(mca_x,1) end;
  while ofs_z<0 do begin inc(ofs_z,32);dec(mca_z,1) end;
  while ofs_x>=32 do begin dec(ofs_x,32);inc(mca_x,1) end;
  while ofs_z>=32 do begin dec(ofs_z,32);inc(mca_z,1) end;
  tmp_tile:=GetTile(mca_x,mca_z);
  tmp_tile.SetOffset(ofs_x*16,ofs_z*16);

  case lowercase(mode) of
    'biomes':tmp_tile.GetBiomesClip(blocks,param1);
    'clip':tmp_tile.GetClip(blocks,param1);
    'above':tmp_tile.GetAbove(blocks,param1,param3 as TSelectionRule,TSelectionMode(param2));
    'below':tmp_tile.GetBelow(blocks,param1,param3 as TSelectionRule,TSelectionMode(param2));
    'top':tmp_tile.GetBelow(blocks,255,param3 as TSelectionRule,TSelectionMode(param2));
    'surface':tmp_tile.GetSurface(blocks);
    'height':tmp_tile.GetHeight(blocks);
    'realheight':tmp_tile.GetRealHeight(blocks,param3 as TSelectionRule,TSelectionMode(param2));
    'density':tmp_tile.GetDensity(blocks,param3 as TSelectionRule,TSelectionMode(param2));
    else assert(false,'无效的投影模式。');
  end;
end;
}

procedure TMCA_Tile_List.Projection(blocks:TChunk_Block; mode:string; floor:integer=0; palette:TMC_Palette=nil);
var mca_x,mca_z,ofs_x,ofs_z:longint;
    tmp_tile:TMCA_Tile;
begin
  mca_x:=0;
  mca_z:=0;
  ofs_x:=blocks.x;
  ofs_z:=blocks.z;
  while ofs_x<0 do begin inc(ofs_x,32);dec(mca_x,1) end;
  while ofs_z<0 do begin inc(ofs_z,32);dec(mca_z,1) end;
  while ofs_x>=32 do begin dec(ofs_x,32);inc(mca_x,1) end;
  while ofs_z>=32 do begin dec(ofs_z,32);inc(mca_z,1) end;
  tmp_tile:=GetTile(mca_x,mca_z);
  tmp_tile.SetOffset(ofs_x*16,ofs_z*16);

  case lowercase(mode) of
    'biomes':     tmp_tile.GetBiomesClip( blocks, floor);
    'clip':       tmp_tile.GetClip(       blocks, floor);
    'above':      tmp_tile.GetAbove(      blocks, floor, palette);
    'below':      tmp_tile.GetBelow(      blocks, floor, palette);
    'top':        tmp_tile.GetBelow(      blocks, blocks.Stream.Size div 1024{4*16*16} - 1, palette);
    'surface':    tmp_tile.GetSurface(    blocks);
    'height':     tmp_tile.GetHeight(     blocks, 'ws');
    'realheight': tmp_tile.GetRealHeight( blocks, palette);
    'density':    tmp_tile.GetDensity(    blocks, palette);
    else assert(false,'无效的投影模式。');
  end;
end;

procedure TMCA_Tile_List.SaveToFile(filename:string);
var BitMap:TBitMap;
    x0,x1,z0,z1:integer;
    BlockIndex:longint;
    pi:integer;
    wth,wtf:word;
    dtmp:record case v:integer of
      0:(vd:dword);
      1:(vb:array[0..3]of byte);
    end;
    tmp_tile:TMCA_Tile;
    source,dest:pbyte;
    srcRect,dstRect:TRect;
begin
  if Self.Count=0 then exit;
  BitMap:=TBitMap.Create;
  BitMap.PixelFormat:=pf32bit;
  x0:=High(integer);
  z0:=High(integer);
  x1:=Low(integer);
  z1:=Low(integer);
  for pi:=0 to Self.count-1 do
    begin
      tmp_tile:=TMCA_Tile(Self.Items[pi]);
      if tmp_tile.Position.x>x1 then x1:=tmp_tile.Position.x;
      if tmp_tile.Position.z>z1 then z1:=tmp_tile.Position.z;
      if tmp_tile.Position.x<x0 then x0:=tmp_tile.Position.x;
      if tmp_tile.Position.z<z0 then z0:=tmp_tile.Position.z;
    end;
  BitMap.SetSize(512*(x1-x0+1),512*(z1-z0+1));
  BitMap.BeginUpdate;
  for pi:=0 to Self.count-1 do
    begin
      tmp_tile:=TMCA_Tile(Self.Items[pi]);
      with srcRect do begin
        Left:=0;
        Right:=512;
        Top:=0;
        Bottom:=512;
      end;
      with dstRect do begin
        Left:=(tmp_tile.Position.x-x0)*512;
        Right:=Left+512;
        Top:=(tmp_tile.Position.z-z0)*512;
        Bottom:=Top+512;
      end;
      //BitMap.Canvas.
      tmp_tile.FBitMap.BeginUpdate;
      //BitMap.Canvas.CopyRect(dstRect,tmp_tile.FBitMap.Canvas,srcRect);
      for wth:=0 to 511 do
        for wtf:= 0 to 511 do
          begin
            dtmp.vd:=pdword(tmp_tile.FBitMap.ScanLine[wth]+4*wtf)^;
            pdword(Bitmap.ScanLine[dstRect.Top+wth]+4*(dstRect.Left+wtf))^:=dtmp.vd;
          end;
      tmp_tile.FBitMap.EndUpdate;
    end;
  BitMap.EndUpdate;
  BitMap.SaveToFile(filename);

  BitMap.Free;
end;

procedure TMCA_Tile_List.SaveAsTiff(filename_without_ext:string);
var Picture:TPicture;
    x0,x1,z0,z1:integer;
    pi:integer;
    wth,wtf:int64;
    tmp_tile:TMCA_Tile;
    srcRect,dstRect:TRect;
    tfw:text;
    dtmp:record case v:integer of
      0:(vd:dword);
      1:(vb:array[0..3]of byte);
    end;
begin
  if Self.Count=0 then exit;

  Picture:=TPicture.Create;
  Picture.BitMap.PixelFormat:=pf32bit;


  x0:=High(integer);
  z0:=High(integer);
  x1:=Low(integer);
  z1:=Low(integer);
  for pi:=0 to Self.count-1 do
    begin
      tmp_tile:=TMCA_Tile(Self.Items[pi]);
      if tmp_tile.Position.x>x1 then x1:=tmp_tile.Position.x;
      if tmp_tile.Position.z>z1 then z1:=tmp_tile.Position.z;
      if tmp_tile.Position.x<x0 then x0:=tmp_tile.Position.x;
      if tmp_tile.Position.z<z0 then z0:=tmp_tile.Position.z;
    end;

  Picture.BitMap.SetSize(512*(x1-x0+1),512*(z1-z0+1));
  //Picture.Bitmap.BeginUpdate;

  for pi:=0 to Self.count-1 do
    begin
      tmp_tile:=TMCA_Tile(Self.Items[pi]);
      with srcRect do begin
        Left:=0;
        Right:=512;
        Top:=0;
        Bottom:=512;
      end;
      with dstRect do begin
        Left:=(tmp_tile.Position.x-x0)*512;
        Right:=Left+512;
        Top:=(tmp_tile.Position.z-z0)*512;
        Bottom:=Top+512;
      end;
      //Picture.BitMap.Canvas.CopyRect(dstRect,tmp_tile.FBitMap.Canvas,srcRect);
      //{
      tmp_tile.FBitMap.BeginUpdate;
      for wth:=0 to 511 do
        for wtf:= 0 to 511 do
          begin
            dtmp.vd:=pdword(tmp_tile.FBitMap.ScanLine[wth]+4*wtf)^;
            pdword(Picture.Bitmap.ScanLine[dstRect.Top+wth]+4*(dstRect.Left+wtf))^:=dtmp.vd;
            //if dtmp.vd<>0 then write(' ',IntToHex(dtmp.vd,8));
          end;
      tmp_tile.FBitMap.EndUpdate;
      //}
    end;

  //Picture.Bitmap.EndUpdate;
  Picture.SaveToFile(filename_without_ext+'.tif','tif');
  //Picture.Bitmap.Free;
  Picture.Free;

  assignfile(tfw,filename_without_ext+'.tfw');
  rewrite(tfw);

  writeln(tfw,1);
  writeln(tfw,0);
  writeln(tfw,0);
  writeln(tfw,-1);
  writeln(tfw,512*x0);
  writeln(tfw,-512*(z0));

  closefile(tfw);

end;

procedure TMCA_Tile_List.Colorize(mode:string;ColorRule:TColorRule=nil);
var pi:integer;
begin
  mode:=lowercase(mode);
  for pi:=0 to Self.Count-1 do
    case (mode) of
      'raw':TMCA_Tile(Self.Items[pi]).Colorize_Raw;
      'fix':TMCA_Tile(Self.Items[pi]).Colorize_Fix;
      'exaggerated':TMCA_Tile(Self.Items[pi]).Colorize_Exaggerated;
      'color':TMCA_Tile(Self.Items[pi]).Colorize_Rule(ColorRule);
      else TMCA_Tile(Self.Items[pi]).Colorize_Raw;
    end;
end;

class function TMCA_Tile_List.AufTypeName:String;
begin
  result:='tile';
end;

end.

