unit color_rule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics;

type
  TColorRule=class
    FStream:TMemoryStream;
  public
    procedure LoadFromFile(filename:string);
    procedure SaveToFile(filename:string);
    procedure RemoveDataColor;
    procedure InitDataColor;
    procedure RemoveAlpha;
  protected
    function GetBlockColor(id:word;data:byte):TColor;
  public
    property BlockColor[id:word;data:byte]:TColor read GetBlockColor;
  public
    constructor Create;
    destructor Destroy;override;
  end;

implementation
//uses Apiglio_Tree;

function TColorRule.GetBlockColor(id:word;data:byte):TColor;
var p:pbyte;
    data_offset:byte;
begin
  p:=FStream.Memory;
  data_offset:=data*4;
  inc(p,id*64+data_offset);
  if (p+3)^ <> 0 then
    begin
      result:=TColor(pdword(p)^);
    end
  else
    begin
      dec(p,data_offset);
      result:=TColor(pdword(p)^);
    end;
end;

procedure TColorRule.LoadFromFile(filename:string);
var tmp:TFileStream;
begin
  tmp:=TFileStream.Create(filename,fmOpenRead);
  if tmp.Size<>4*16*4096 then begin raise Exception.Create('颜色规则文件大小错误。');exit end;
  FStream.LoadFromStream(tmp);
  tmp.Free;
end;
procedure TColorRule.SaveToFile(filename:string);
begin
  FStream.SaveToFile(filename);
end;
procedure TColorRule.InitDataColor;
var Id:word;
    Data:byte;
    p:pbyte;
begin
  p:=pbyte(FStream.Memory);
  for Id:=0 to 4095 do
    for Data:=1 to 15 do
      (pdword(p+Id*64+Data*4))^:=(pdword(p+Id*64))^;
end;
procedure TColorRule.RemoveDataColor;
var Id:word;
    Data:byte;
    p:pbyte;
begin
  p:=pbyte(FStream.Memory);
  for Id:=0 to 4095 do
    for Data:=1 to 15 do
      (p+Id*64+Data*4+3)^:=0;
end;
procedure TColorRule.RemoveAlpha;
var Id:word;
    Data:byte;
    p:pbyte;
begin
  p:=pbyte(FStream.Memory);
  for Id:=0 to 4095 do
    for Data:=0 to 15 do
      (p+Id*64+Data*4+3)^:=255;
end;

constructor TColorRule.Create;
begin
  inherited Create;
  FStream:=TMemoryStream.Create;
  FStream.Size:=4*16*4096;
end;
destructor TColorRule.Destroy;
begin
  FStream.Free;
  inherited Destroy;
end;



end.

