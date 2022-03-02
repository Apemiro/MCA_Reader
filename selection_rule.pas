unit selection_rule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

  TSelectionMode=(smExclude=0,smJust=1);

  TSelectionRule=class
  private
    FStream:TMemoryStream;
    //四位一个方块，四个字节为一组，add blk dat nul（与TBitMap的BGRa格式统一）
    //dat>15时忽略dat限制
  public
    Count:integer;
  public
    procedure LoadFromFile(filename:string);
    procedure LoadFromOldFile(filename:string);//兼容三字节的版本
    procedure SaveToFile(filename:string);

    procedure AddBlock(blk:word;data:byte=16);
  protected
    function GetJustSelection(blk:dword):dword;
    function GetExcludeSelection(blk:dword):dword;
  public
    property JustSelection[block:dword]:dword read GetJustSelection;
    property ExcludeSelection[block:dword]:dword read GetExcludeSelection;
  public
    constructor Create;
    destructor Destroy;override;
  end;


implementation



procedure TSelectionRule.AddBlock(blk:word;data:byte=16);
begin
  FStream.Position:=FStream.Size;
  FStream.WriteDWord((data shl 16) + SwapEndian(blk));
end;

function TSelectionRule.GetJustSelection(blk:dword):dword;
var tmp:dword;
    t_dat,b_dat:byte;
begin
  result:=blk;
  FStream.Position:=0;
  while FStream.Position<FStream.Size do
    begin
      tmp:=FStream.ReadDWord;
      b_dat:=(blk shr 16) mod 256;
      t_dat:=(tmp shr 16) mod 256;
      if ((tmp shl 16) = (blk shl 16)) and ((t_dat>15) or (t_dat=b_dat)) then exit;
    end;
  result:=0;
end;

function TSelectionRule.GetExcludeSelection(blk:dword):dword;
var tmp:dword;
    t_dat,b_dat:byte;
begin
  result:=0;
  FStream.Position:=0;
  while FStream.Position<FStream.Size do
    begin
      tmp:=FStream.ReadDWord;
      b_dat:=(blk shr 16) mod 256;
      t_dat:=(tmp shr 6) mod 256;
      if ((tmp shl 16) = (blk shl 16)) and ((t_dat>15) or (t_dat=b_dat)) then exit;
    end;
  result:=blk;
end;

procedure TSelectionRule.LoadFromFile(filename:string);
begin
  FStream.LoadFromFile(filename);
end;

procedure TSelectionRule.LoadFromOldFile(filename:string);
var old:TMemorystream;
begin
  old:=TMemoryStream.Create;
  old.LoadFromFile(filename);
  old.Position:=0;
  FStream.SetSize(0);
  FStream.Position:=0;
  while old.Position < old.Size do
    begin
      FStream.CopyFrom(old,3);
      FStream.WriteByte(0);
    end;
  Count:=FStream.Size div 4;
end;

procedure TSelectionRule.SaveToFile(filename:string);
begin
  FStream.SaveToFile(filename);
  Count:=FStream.Size div 4;
end;

constructor TSelectionRule.Create;
begin
  inherited Create;
  FStream:=TMemoryStream.Create;
  FStream.SetSize(0);
end;
destructor TSelectionRule.Destroy;
begin
  FStream.Free;
  inherited Destroy;
end;


end.

