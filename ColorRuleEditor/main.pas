unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls;

const
  R_width=240;
  B_height=80;

type

  { TColorButton }
  TColorButton = class(TShape)
  public
    constructor Create(Acolor:TColor);
    procedure SelectColor(Sender:TObject;but:TMouseButton;shif:TshiftState;x,y:Longint);
    procedure SetAColor(Sender:TObject;but:TMouseButton;shif:TshiftState;x,y:Longint);

  end;

  { TBlockRule }
  TBlockRule = class(TShape)
  public
    Id_pad,Name_pad:TShape;
    ListId:byte;
    BlockId:word;
    Icon_pad:TImage;
    datacolor:array[0..15]of TColorButton;
  public
    constructor Create(id:byte);
    procedure EditColor(Sender:TObject;but:TMouseButton;shif:TshiftState;x,y:Longint);
    procedure LoadfromColorStream(seeking:dword);
    procedure ChangeBoundary(Sender: TObject);
  end;


  { TColorForm }

  TColorForm = class(TForm)
    Button_Colorize: TButton;
    Button_Load: TButton;
    Button_Save: TButton;
    Button_NextRule: TButton;
    Button_NextBlock: TButton;
    Button_PrevRule: TButton;
    Button_PrevBlock: TButton;
    Edit_ColorG: TEdit;
    Edit_ColorB: TEdit;
    Edit_HexColor: TEdit;
    Edit_GotoPage: TEdit;
    Edit_ColorR: TEdit;
    GroupBox_View: TGroupBox;
    GroupBox_File: TGroupBox;
    GroupBox_Page: TGroupBox;
    GroupBox_Edit: TGroupBox;
    Label_DecG: TLabel;
    Label_DecR: TLabel;
    Label_Hex: TLabel;
    Label_DecB: TLabel;
    ScrollBox_View: TScrollBox;
    ScrollBox_Color: TScrollBox;
    Shape1: TShape;
    procedure Button_ColorizeClick(Sender: TObject);
    procedure Button_LoadClick(Sender: TObject);
    procedure Button_SaveClick(Sender: TObject);
    procedure Edit_ColorBChange(Sender: TObject);
    procedure Edit_ColorGChange(Sender: TObject);
    procedure Edit_ColorRChange(Sender: TObject);
    procedure Edit_HexColorChange(Sender: TObject);
    procedure FormChangeBounds(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { private declarations }
  public
    BlockRule:array[0..15]of TBlockRule;
  end;

var
  ColorForm: TColorForm;
  ColorButton:array[0..323]of TColorButton;
  ColorFile:TMemoryStream;

  CurrentColor:TColor;
  DO_NOT_CHANGE:boolean;

implementation

{$R *.lfm}

{ TBlockRule }
constructor TBlockRule.Create(id:byte);
var i:byte;
begin
  inherited Create(Application);
  Self.ListId:=id;
  Name_pad:=TShape.Create(Owner);
  Id_pad:=TShape.Create(Owner);

  Brush.Style:=bsClear;
  Visible:=false;

  //Icon_pad:=TImage.Create(Owner);
  for i:=0 to 15 do
    begin
      DataColor[i]:=TColorButton.Create($FFFFFF);
      DataColor[i].OnMouseUp:=@DataColor[i].SetAColor;
      DataColor[i].Hint:=IntToStr(i);
      DataColor[i].ShowHint:=true;
      DataColor[i].parent:=ColorForm.ScrollBox_View;
      //DataColor[i].Top:=(Self.Height div 5)*(i div 8);
      //DataColor[i].Left:=100+(Self.Height div 5)*(i mod 8);
      //DataColor[i].Width:=Self.Height div 5 + 1;
      //DataColor[i].Height:=Self.Height div 5 + 1;

    end;
  //OnChangeBounds:=Self.ChangeBoundary;
  OnMouseWheel:=ColorForm.ScrollBox_View.OnMouseWheel;
end;

procedure TBlockRule.EditColor(Sender:TObject;but:TMouseButton;shif:TshiftState;x,y:Longint);
begin

end;

procedure TBlockRule.LoadfromColorStream(seeking:dword);
begin

end;

procedure TBlockRule.ChangeBoundary(Sender: TObject);
var i:byte;
begin
  for i:=0 to 15 do
    begin           {
      if Self.Height>60 then
        begin                  }
          DataColor[i].Top:=Self.Top+(Self.Height*2 div 6)*(i div 8)+(Self.Height div 6);
          DataColor[i].Left:=Self.Left+(Self.Height*2 div 6)*(i mod 8)+50;
          DataColor[i].Width:=(Self.Height*2 div 6) + 1;
          DataColor[i].Height:=(Self.Height*2 div 6) + 1;  {
        end
      else
        begin
          DataColor[i].Top:=Self.Top+(Self.Height div 6);
          DataColor[i].Left:=Self.Left+(Self.Height * 2 div 3)*(i)+(Self.Height div 6)+50;
          DataColor[i].Width:=Self.Height * 2 div 3 + 1;
          DataColor[i].Height:=Self.Height * 2 div 3 + 1;
        end;   }
    end;
end;

{ TColorButton }

constructor TColorButton.Create(Acolor:TColor);
begin
  inherited Create(Application);
  Self.brush.color:=Acolor;
  OnMouseUp:=@SelectColor;
end;

procedure TColorButton.SelectColor(Sender:TObject;but:TMouseButton;shif:TshiftState;x,y:Longint);
begin
  CurrentColor:=(Sender as TColorButton).Brush.Color;
  ColorForm.Edit_HexColor.Color:=CurrentColor;
  if (CurrentColor and $808080)= 0 then ColorForm.Edit_HexColor.Font.Color:=$FFFFFF
  else ColorForm.Edit_HexColor.Font.Color:=0;
  ColorForm.Edit_HexColor.Text:=IntToHex(CurrentColor,6);
  DO_NOT_CHANGE:=true;
  ColorForm.Edit_ColorB.Text:=IntToStr((CurrentColor div 65536)mod 256);
  ColorForm.Edit_ColorG.Text:=IntToStr((CurrentColor div 256)mod 256);
  ColorForm.Edit_ColorR.Text:=IntToStr(CurrentColor mod 256);
  DO_NOT_CHANGE:=false;

end;

procedure TColorButton.SetAColor(Sender:TObject;but:TMouseButton;shif:TshiftState;x,y:Longint);
begin
  (Sender as TColorButton).Brush.Color:=CurrentColor;
  ColorForm.Edit_GotoPage.Text:=IntToHex((Sender as TColorButton).Brush.Color,6);
end;

function DeltaDeg(a1,a2:word):byte;
var ans1,ans2:integer;
begin
  ans1:=a1-a2;
  ans2:=a2-a1;
  while ans1>=360 do ans1:=ans1-360;
  while ans1<0 do ans1:=ans1+360;
  while ans2>=360 do ans2:=ans2-360;
  while ans2<0 do ans2:=ans2+360;
  if ans1>ans2 then result:=ans2
  else result:=ans1;
end;

procedure HV2RGB(const Hue,Light:integer;var R,G,B:byte);//hue in [0,350] light in [-4,4]
begin
  R:=0;G:=0;B:=0;

  if DeltaDeg(hue,0)<=60 then R:=255;
  if DeltaDeg(hue,120)<=60 then G:=255;
  if DeltaDeg(hue,240)<=60 then B:=255;

  if (DeltaDeg(hue,90)<30) or (DeltaDeg(hue,270)<30) then R:=((DeltaDeg(hue,180)-60)*256)div 60 -1;
  if (DeltaDeg(hue,30)<30) or (DeltaDeg(hue,210)<30) then G:=((120-DeltaDeg(hue,120))*256)div 60 -1;
  if (DeltaDeg(hue,150)<30) or (DeltaDeg(hue,330)<30) then B:=((120-DeltaDeg(hue,240))*256)div 60 -1;

  case Light of
    4:
      begin
        R:=255;
        G:=255;
        B:=255;
      end;
    3:
      begin
        R:=R+(256-R)*3 div 4;
        G:=G+(256-G)*3 div 4;
        B:=B+(256-B)*3 div 4;
      end;
    2:
      begin
        R:=R+(256-R) div 2;
        G:=G+(256-G) div 2;
        B:=B+(256-B) div 2;
      end;
    1:
      begin
        R:=R+(256-R) div 4;
        G:=G+(256-G) div 4;
        B:=B+(256-B) div 4;
      end;
    0:
      begin
        //
      end;
    -1:
      begin
        R:=R*3 div 4;
        G:=G*3 div 4;
        B:=B*3 div 4;
      end;
    -2:
      begin
        R:=R div 2;
        G:=G div 2;
        B:=B div 2;
      end;
    -3:
      begin
        R:=R div 4;
        G:=G div 4;
        B:=B div 4;
      end;
    -4:
      begin
        R:=0;
        G:=0;
        B:=0;
      end;
    else ;
  end;

end;

procedure InitColorBlock;
var r,g,b:byte;
    hue,brightness,l:shortint;
    h:word;
    tmpColor:TColor;
    tmp:TColorButton;
begin
  //临时用作它用

    for hue:=-1 to 35 do
      for brightness:=0 to 6 do
          begin
            if hue = -1 then
             begin
              case brightness of
                0:begin r:=$00;g:=$00;b:=$00 end;
                1:begin r:=$2A;g:=$2A;b:=$2A end;
                2:begin r:=$55;g:=$55;b:=$55 end;
                3:begin r:=$7F;g:=$7F;b:=$7F end;
                4:begin r:=$A9;g:=$A9;b:=$A9 end;
                5:begin r:=$D6;g:=$D6;b:=$D6 end;
                6:begin r:=$FF;g:=$FF;b:=$FF end;
                else ;
              end;
             end
            else
             begin
              h:=hue*10;//[0,350]
              l:=brightness - 3;//[-4,4]
              HV2RGB(h,l,r,g,b);
             end;
            tmpColor:=(r shl 0)+(g shl 8)+(b shl 16);
            tmp:=TColorButton.Create(tmpColor);
            tmp.Hint:=IntToHex(tmpColor,6);
            //tmp.Hint:='('+IntToStr(h)+','+IntToStr(l)+'):'+IntToHex(tmpColor,6);
            tmp.ShowHint:=true;
            tmp.Parent:=ColorForm.ScrollBox_Color;
            tmp.Width:=28;
            tmp.Height:=28;
            tmp.Top:=(hue+1)*27;
            tmp.Left:=5+(brightness)*27;


            ColorButton[7+hue*7+brightness]:=tmp;
          end;
end;

procedure InitBlockRule;
var i:byte;
begin
  for i:=0 to 15 do
    begin
      ColorForm.BlockRule[i]:=TBlockRule.Create(i);
      ColorForm.BlockRule[i].Parent:=ColorForm.ScrollBox_View;
      ColorForm.BlockRule[i].Height:=61;
      ColorForm.BlockRule[i].Width:=ColorForm.ScrollBox_View.Width - 35;
      ColorForm.BlockRule[i].Top:=10+60*i;
      ColorForm.BlockRule[i].Left:=5;
      ColorForm.BlockRule[i].Caption:='';
      ColorForm.BlockRule[i].ChangeBoundary(nil);

      //ColorForm.BlockRule[i].Brush.Style:=bsSolid;

      ColorForm.BlockRule[i].OnMouseWheel:=ColorForm.ScrollBox_View.OnMouseWheel;//没有达到我想要的效果
    end;
end;

{ TColorForm }

procedure TColorForm.FormCreate(Sender: TObject);
begin
  Width:=640;
  height:=440;
  position:=poScreenCenter;

  Button_PrevRule.top:=16;
  Button_PrevBlock.top:=16;
  Edit_GotoPage.top:=16;
  Button_NextBlock.top:=16;
  Button_NextRule.top:=16;

  InitColorBlock;
  InitBlockRule;

  FormResize(nil);



end;

procedure TColorForm.Button_LoadClick(Sender: TObject);
begin
  ColorFile.Free;
  ColorFile.LoadFromFile('DefaultColorRule.dat');
end;

procedure TColorForm.Button_ColorizeClick(Sender: TObject);
begin
  CurrentColor:=StrToInt('$'+ColorForm.Edit_HexColor.Text);
  ColorForm.Edit_HexColor.Color:=CurrentColor;
end;

procedure TColorForm.Button_SaveClick(Sender: TObject);
begin
  ColorFile.SaveToFile('DefaultColorRule.dat');
end;

procedure TColorForm.Edit_ColorBChange(Sender: TObject);
var str:string;
begin
  if DO_NOT_CHANGE then exit;
  ColorForm.Edit_HexColor.Text:=IntToHex(CurrentColor,6);
  str:=ColorForm.Edit_HexColor.Text;
  delete(str,1,2);
  str:=IntToHex(StrToInt((Sender as TEdit).Text)mod 256,2)+str;
  (Sender as TEdit).Text:=IntToStr(StrToInt((Sender as TEdit).Text)mod 256);
  ColorForm.Edit_HexColor.Text:=str;
  CurrentColor:=StrToInt('$'+ColorForm.Edit_HexColor.Text);
  ColorForm.Edit_HexColor.Color:=CurrentColor;
  if (CurrentColor and $808080)= 0 then ColorForm.Edit_HexColor.Font.Color:=$FFFFFF
  else ColorForm.Edit_HexColor.Font.Color:=0;
end;

procedure TColorForm.Edit_ColorGChange(Sender: TObject);
var str1,str2:string;
begin
  if DO_NOT_CHANGE then exit;
  ColorForm.Edit_HexColor.Text:=IntToHex(CurrentColor,6);
  str1:=ColorForm.Edit_HexColor.Text;
  str2:=ColorForm.Edit_HexColor.Text;
  delete(str1,3,4);
  delete(str2,1,4);
  str1:=str1+IntToHex(StrToInt((Sender as TEdit).Text)mod 256,2)+str2;
  (Sender as TEdit).Text:=IntToStr(StrToInt((Sender as TEdit).Text)mod 256);
  ColorForm.Edit_HexColor.Text:=str1;
  CurrentColor:=StrToInt('$'+ColorForm.Edit_HexColor.Text);
  ColorForm.Edit_HexColor.Color:=CurrentColor;
  if (CurrentColor and $808080)= 0 then ColorForm.Edit_HexColor.Font.Color:=$FFFFFF
  else ColorForm.Edit_HexColor.Font.Color:=0;
end;

procedure TColorForm.Edit_ColorRChange(Sender: TObject);
var str:string;
begin
  if DO_NOT_CHANGE then exit;
  ColorForm.Edit_HexColor.Text:=IntToHex(CurrentColor,6);
  str:=ColorForm.Edit_HexColor.Text;
  delete(str,5,2);
  str:=str+IntToHex(StrToInt((Sender as TEdit).Text)mod 256,2);
  (Sender as TEdit).Text:=IntToStr(StrToInt((Sender as TEdit).Text)mod 256);
  ColorForm.Edit_HexColor.Text:=str;
  CurrentColor:=StrToInt('$'+ColorForm.Edit_HexColor.Text);
  ColorForm.Edit_HexColor.Color:=CurrentColor;
  if (CurrentColor and $808080)= 0 then ColorForm.Edit_HexColor.Font.Color:=$FFFFFF
  else ColorForm.Edit_HexColor.Font.Color:=0;
end;

procedure TColorForm.Edit_HexColorChange(Sender: TObject);
begin
  //
end;

procedure TColorForm.FormChangeBounds(Sender: TObject);
begin
  //
end;

procedure TColorForm.FormResize(Sender: TObject);
var i:byte;
begin
  if Width<640 then Width:=640;
  if Height<440 then Height:=440;
  with GroupBox_view do
    begin;
      Width:=Self.Width-R_Width-30;
      Height:=Self.Height-B_height-30;
      Top:=10;
      Left:=10;
    end;
  with GroupBox_edit do
    begin;
      Width:=R_Width;
      Height:=Self.Height-B_height-30;
      Top:=10;
      Left:=Self.Width-R_Width-10;
    end;
  with GroupBox_page do
    begin;
      Width:=Self.Width-R_Width-30;
      Height:=B_height;
      Top:=Self.Height-B_height-10;
      Left:=10;
    end;
  with GroupBox_file do
    begin;
      Width:=R_Width;
      Height:=B_height;
      Top:=Self.Height-B_height-10;
      Left:=Self.Width-R_Width-10;
    end;

  with ScrollBox_Color do
    begin;
      Width:=R_Width-15;
      Height:=Self.Height-B_height-30-70-30;
      Top:=45+30;
      Left:=5;
    end;
  with ScrollBox_View do
    begin;
      Width:=GroupBox_view.Width-10;
      Height:=GroupBox_view.Height-30;
      Top:=5;
      Left:=5;
    end;

  for i:=0 to 15 do
    begin
      BlockRule[i].Height:=(ScrollBox_View.Height div 8)+1;
      BlockRule[i].Width:=ColorForm.ScrollBox_View.Width - 35;
      BlockRule[i].Top:=10+(ScrollBox_View.Height div 8)*i;
      BlockRule[i].Left:=5;
      BlockRule[i].ChangeBoundary(nil);
    end;

  Edit_GotoPage.Width:=(GroupBox_Page.Width-6*8) div 3;
  Button_PrevBlock.Width:=(GroupBox_Page.Width-6*8) div 6;
  Button_PrevRule.Width:=(GroupBox_Page.Width-6*8) div 6;
  Button_NextRule.Width:=(GroupBox_Page.Width-6*8) div 6;
  Button_NextBlock.Width:=(GroupBox_Page.Width-6*8) div 6;

  Button_PrevRule.left:=8;
  Button_PrevBlock.left:=8+Button_PrevRule.Width+8;
  Edit_GotoPage.left:=8+Button_PrevRule.Width+8+Button_PrevBlock.Width+8;
  Button_NextBlock.left:=8+Button_PrevRule.Width+8+Button_PrevBlock.Width+8+Edit_GotoPage.Width+8;
  Button_NextRule.left:=8+Button_PrevRule.Width+8+Button_PrevBlock.Width+8+Edit_GotoPage.Width+8+Button_NextBlock.Width+8;




end;



end.

