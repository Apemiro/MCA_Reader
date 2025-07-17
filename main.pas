//{$define insert}
//{$define TEST}

////Z*32+X


unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Zstream, LazUtf8,
  StdCtrls, ComCtrls, Menus, Windows
  {$ifndef insert}, Apiglio_Useful, Auf_Ram_Var, aufscript_frame, apiglio_tree,
  entities_definition, blocks_definition, mca_tile, mca_base, color_rule,
  selection_rule, mc_world{$endif};

const version_number='2.0';

type

  { TFormMain }
  TFormMain = class(TForm)
    Frame_AufScript1: TFrame_AufScript;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem_Option_Help: TMenuItem;
    MenuItem_Setting: TMenuItem;
    MenuItem_Option_About: TMenuItem;
    MenuItem_File_OpenMCA: TMenuItem;
    MenuItem_File_Open: TMenuItem;
    MenuItem_File: TMenuItem;
    MenuItem_Option: TMenuItem;
    StatusBar1: TStatusBar;
    procedure AufInit(scpt:TAufScript);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure MenuItem_Option_AboutClick(Sender: TObject);
    procedure MenuItem_Option_HelpClick(Sender: TObject);

  private
    { private declarations }
  public

  end;

var
  FormMain: TFormMain;

  MCA_Tile_List:TMCA_Tile_List;
  Entities_List:TEntities;

implementation
uses form_mapviewer;

{$R *.lfm}

procedure command_decoder(var str:string);
begin
  str:=utf8towincp(str);
end;

procedure IO_writetipLn(Sender:TObject;str:string);inline;
begin
  FormMain.Frame_AufScript1.Auf.Script.writeln(str);
end;
procedure IO_error(Sender:TObject;str:string);inline;
begin
  FormMain.Frame_AufScript1.Auf.Script.send_error(str);
end;
procedure IO_writetip(Sender:TObject;str:string);inline;
begin
  FormMain.Frame_AufScript1.Auf.Script.write(str);
end;
procedure IO_pause(Sender:TObject);
begin
  //
end;


//AufScript函数

procedure Func_TileList_Export(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    filename,mode:string;
    TmpColorRule:TColorRule;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToString(1, filename) then exit;
  if not AAuf.TryArgToStrParam(2, ['raw','fix','exa','color'], false, mode) then exit;
  case mode of
    'raw':MCA_Tile_List.Colorize('raw');
    'fix':MCA_Tile_List.Colorize('fix');
    'exa':MCA_Tile_List.Colorize('exaggerated');
    'color':
      begin
        TmpColorRule:=TColorRule.create;
        TmpColorRule.LoadFromFile('DefaultColorRule.dat');
        MCA_Tile_List.Colorize('color',TmpColorRule);
        TmpColorRule.Free;
      end
    else MCA_Tile_List.Colorize('raw'); //并不会触发
  end;

  //MCA_Tile_List.SaveToFile(filename+'.png');
  MCA_Tile_List.SaveAsTiff(filename);
  AufScpt.writeln('已将方块平面图保存在'+filename+'中。');
end;

procedure Func_Entities_Export(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    filename:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(1, filename) then exit;
  //Entities_List.SaveToFile(filename);
  Entities_List.SaveAsShp(filename);
  AufScpt.writeln('已将实体列表保存在'+filename+'中。');
end;


//大功能

procedure Func_MCA2Tile(Sender:TObject);//read_tile filename[,x,z]
var AufScpt:TAufScript;
    AAuf:TAuf;
    filename,tmp,tmp2:string;
    chunkN,po:integer;
    tmp_tile:TMCA_Tile;
    mca:TMCA_Stream;
    chunk:TChunk_Stream;
    blocks:TChunk_Block;
    tree:TATree;
    //sel:TSelectionRule;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(2, filename) then exit;

  mca:=TMCA_Stream.Create;
  chunk:=TChunk_Stream.Create;
  tree:=TATree.Create;
  blocks:=TChunk_Block.Create;
  //sel:=TSelectionRule.Create;
  //sel.AddBlock(473);

  mca.LoadFromFile(filename);
  for chunkN:=0 to 1023 do
    begin
      Application.ProcessMessages;
      try
        if not mca.ChunkAvailable(chunkN) then continue;
        if not chunk.LoadFromMCA(chunkN,mca) then continue;
        tree.Clear;
        chunk.Decode(tree);
        blocks.LoadFromTree(tree, nil);
        //MCA_Tile_List.GetChunkPlan(blocks,'top',0,Byte(smExclude),sel);
        MCA_Tile_List.Projection(blocks,'realheight',0,nil);

      except
        AufScpt.writeln('警告：mca['+IntToStr(mca.x)+','+IntToStr(mca.z)+'].chunk['+IntToStr(chunkN)+']读取失败。');
        tree.JsonFileMode:=jfmAnalysis;
        tree.PrintJSON;
        tree.JsonFileMode:=jfmStored;
      end;
    end;

  //sel.Free;
  blocks.Free;
  tree.Free;
  chunk.Free;
  mca.Free;

end;

procedure Func_about(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AufScpt.writeln('Apiglio MCA Reader');
  AufScpt.writeln('version '+version_number);
end;
procedure Func_mapViewer(Sender:TObject);
begin
  FormViewer.Show;
end;

procedure Func_viewBlockPalette(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  AufScpt.writeln(defaultBlocks.ExportToString(#13#10));
end;
procedure Func_viewBiomePalette(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  AufScpt.writeln(defaultBiomes.ExportToString(#13#10));
end;


procedure Func_newMCA(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TMCA_Stream.Create;
  pqword(arv.Head)^:=qword(obj);
end;
procedure Func_freeMCA(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TMCA_Stream) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TMCA_Stream对象，未能正常释放对象。');
      exit
    end;
  (obj as TMCA_Stream).Free;
end;
procedure Func_loadMCA(Sender:TObject);//xxx $8[],"mca_filename"
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    filename:string;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  if not AAuf.TryArgToString(2,filename) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TMCA_Stream) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TMCA_Stream对象，代码未执行。');
      exit
    end;
  (obj as TMCA_Stream).LoadFromFile(filename);
end;
procedure Func_DoesMCAHasNotChunk(Sender:TObject);//xxx $8[],chunkNo,:label
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    chunk_number:dword;
    addr:pRam;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  if not AAuf.TryArgToDword(2,chunk_number) then exit;
  if not AAuf.TryArgToAddr(3,addr) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TMCA_Stream) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TMCA_Stream对象，代码未执行。');
      exit
    end;
  if not (obj as TMCA_Stream).ChunkAvailable(chunk_number) then AufScpt.jump_addr(addr);
end;

procedure Func_newChunk(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TChunk_Stream.Create;
  pqword(arv.Head)^:=qword(obj);
end;
procedure Func_freeChunk(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TChunk_Stream) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TChunk_Stream对象，未能正常释放对象。');
      exit
    end;
  (obj as TChunk_Stream).Free;
end;
procedure Func_loadChunk(Sender:TObject);//xxx $8[],$8[],chunkNo
var AufScpt:TAufScript;
    AAuf:TAuf;
    chk,mca:TAufRamVar;
    chunk_number:dword;
    chk_obj,mca_obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],chk) then exit;
  if not AAuf.TryArgToARV(2,8,8,[ARV_FixNum],mca) then exit;
  if not AAuf.TryArgToDword(3,chunk_number) then exit;
  chk_obj:=TObject(pqword(chk.Head)^);
  if not (chk_obj is TChunk_Stream) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TChunk_Stream对象，代码未执行。');
      exit
    end;
  mca_obj:=TObject(pqword(mca.Head)^);
  if not (mca_obj is TMCA_Stream) then
    begin
      AufScpt.send_error('警告：第二个参数不能转化为TMCA_Stream对象，代码未执行。');
      exit
    end;
  (chk_obj as TChunk_Stream).LoadFromMCA(chunk_number,mca_obj as TMCA_Stream);
end;
procedure Func_loadChunkFromDat(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    chk:TObject;
    fname:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TChunk_Stream,chk) then exit;
  if not AAuf.TryArgToString(2,fname) then exit;
  (chk as TChunk_Stream).LoadFromDAT(fname);
end;
procedure Func_decodeChunk(Sender:TObject);//xxx $8[],$8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    tree,chk:TAufRamVar;
    tree_obj,chk_obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],chk) then exit;
  if not AAuf.TryArgToARV(2,8,8,[ARV_FixNum],tree) then exit;
  chk_obj:=TObject(pqword(chk.Head)^);
  if not (chk_obj is TChunk_Stream) then
    begin
      AufScpt.send_error('警告：第二个参数不能转化为TChunk_Stream对象，代码未执行。');
      exit
    end;
  tree_obj:=TObject(pqword(tree.Head)^);
  if not (tree_obj is TATree) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TATree对象，代码未执行。');
      exit
    end;
  (chk_obj as TChunk_Stream).Decode(tree_obj as TATree);
end;

procedure Func_newTree(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TATree.Create;
  pqword(arv.Head)^:=qword(obj);
end;
procedure Func_freeTree(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TATree) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TATree对象，未能正常释放对象。');
      exit
    end;
  (obj as TATree).Free;
end;
procedure Func_clearTree(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TATree) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TATree对象，代码未执行。');
      exit
    end;
  (obj as TATree).Clear;
end;
procedure Func_Tree2Json(Sender:TObject);//xxx $8[],filename[,opt]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    filename,option:string;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  if not AAuf.TryArgToString(2,filename) then exit;
  if AAuf.ArgsCount>3 then begin
    if not AAuf.TryArgToStrParam(3,['analysis','stored','entries'],false,option) then exit;
  end else begin
    option:='stored';
  end;

  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TATree) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TATree对象，代码未执行。');
      exit
    end;
  case lowercase(option)[1] of
    'a':(obj as TATree).JsonFileMode:=jfmAnalysis;
    'e':(obj as TATree).JsonFileMode:=jfmEntries;
    else (obj as TATree).JsonFileMode:=jfmStored;
  end;
  try
    (obj as TATree).PrintJSON(filename+'.json');
  except
    AufScpt.send_error('警告：Json文件导出失败，请文件名是否有效且文件是否被占用。');
  end;
  (obj as TATree).JsonFileMode:=jfmStored;
end;
procedure Func_infoTree(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    obj:TObject;
    tmp:TAListUnit;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToObject(1,TATree,obj) then exit;
  AufScpt.write('["');
  with TATree(obj) do begin
    CurrentInto(root.Achild.first.obj as TATreeUnit);
    CurrentInto('Level');
    tmp:=Current.Achild.first;
    while tmp<>nil do begin
      AufScpt.write(TATreeUnit(tmp.obj).name);
      tmp:=tmp.next;
      if tmp<>nil then AufScpt.write('","');
    end;
    AufScpt.writeln('"]');
  end;
end;
procedure Func_DoesTreeHasPalette(Sender:TObject);//xxx $8[],:label
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    addr:pRam;
    obj:TObject;
    tmpBlock:TChunk_Block;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  if not AAuf.TryArgToAddr(2,addr) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TATree) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TATree对象，代码未执行。');
      exit
    end;
  tmpBlock:=TChunk_Block.Create;
  if tmpBlock.HasPalette(obj as TATree) then AufScpt.jump_addr(addr);;
  tmpBlock.Free;
end;
procedure Func_DoesTreeHasHeightMaps(Sender:TObject);//xxx $8[],:label
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    addr:pRam;
    obj:TObject;
    tmpBlock:TChunk_Block;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  if not AAuf.TryArgToAddr(2,addr) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TATree) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TATree对象，代码未执行。');
      exit
    end;
  tmpBlock:=TChunk_Block.Create;
  if tmpBlock.HasHeightMaps(obj as TATree) then
    begin
      AufScpt.jump_addr(addr);

    end;
  tmpBlock.Free;
end;

procedure Func_newBlock(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TChunk_Block.Create;
  pqword(arv.Head)^:=qword(obj);
end;
procedure Func_freeBlock(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TChunk_Block) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TChunk_Block对象，未能正常释放对象。');
      exit
    end;
  (obj as TChunk_Block).Free;
end;
procedure Func_extractBlock(Sender:TObject);//xxx $8[],$8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    blk,tree:TAufRamVar;
    blk_obj,tree_obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],blk) then exit;
  if not AAuf.TryArgToARV(2,8,8,[ARV_FixNum],tree) then exit;
  blk_obj:=TObject(pqword(blk.Head)^);
  if not (blk_obj is TChunk_Block) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TChunk_Block对象，代码未执行。');
      exit
    end;
  tree_obj:=TObject(pqword(tree.Head)^);
  if not (tree_obj is TATree) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TATree对象，代码未执行。');
      exit
    end;
  (blk_obj as TChunk_Block).LoadFromTree(tree_obj as TAtree, nil);
end;
procedure Func_Block2Txt(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
    filename:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  if not AAuf.TryArgToString(2,filename) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TChunk_Block) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TChunk_Block对象，未能正常释放对象。');
      exit
    end;
  (obj as TChunk_Block).SaveToFile(filename+'.txt');
end;
procedure Func_Block2Chunk(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
    filename:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  if not AAuf.TryArgToString(2,filename) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TChunk_Block) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TChunk_Block对象，未能正常释放对象。');
      exit
    end;
  (obj as TChunk_Block).SaveByteToFile(filename+'.chunk');
end;
procedure Func_BlockHeightMap2Txt(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
    filename:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  if not AAuf.TryArgToString(2,filename) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TChunk_Block) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TChunk_Block对象，未能正常释放对象。');
      exit
    end;
  (obj as TChunk_Block).SaveHeightMapToFile(filename+'.txt');
end;



procedure Func_newTile(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TMCA_Tile_List.Create;
  pqword(arv.Head)^:=qword(obj);
end;
procedure Func_freeTile(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TMCA_Tile_List) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TMCA_Tile_List对象，未能正常释放对象。');
      exit
    end;
  (obj as TMCA_Tile_List).Free;
end;
procedure Func_Tile2Bmp(Sender:TObject);//xxx $8[],filename
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
    filename:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  if not AAuf.TryArgToString(2,filename) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TMCA_Tile_List) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TMCA_Tile_List对象，代码未执行。');
      exit
    end;
  (obj as TMCA_Tile_List).SaveToFile(filename+'.bmp');
end;
procedure Func_Tile2Tiff(Sender:TObject);//xxx $8[],filename
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
    filename:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  if not AAuf.TryArgToString(2,filename) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TMCA_Tile_List) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TMCA_Tile_List对象，代码未执行。');
      exit
    end;
  (obj as TMCA_Tile_List).SaveAsTiff(filename);
end;
procedure Func_getTile(Sender:TObject);//xxx $8[],$8[],p1,p2,p3
var AufScpt:TAufScript;
    AAuf:TAuf;
    tile,blk,sel:TAufRamVar;
    tile_obj,blk_obj,sel_obj:TObject;
    sel_mode:TSelectionMode;
    sel_mode_str:string;
    floor:dword;

    procedure SetSelectionRule(selrule,selmode:byte);
    begin
      if selrule*selmode=0 then begin sel_obj:=nil;sel_mode:=smExclude;exit end;
      if not AAuf.TryArgToARV(selrule,8,8,[ARV_FixNum],sel) then exit;
      if not AAuf.TryArgToString(selmode,sel_mode_str) then exit;

      sel_obj:=TObject(pqword(sel.Head)^);
      if not (sel_obj is TSelectionRule) then begin
        AufScpt.send_error('警告：p'+IntToStr(selrule-2)+'不能转化为TSelectionRule对象，代码未执行。');exit
      end;
      case lowercase(sel_mode_str) of
        'just','j','include','i':sel_mode:=smJust;
        else sel_mode:=smExclude;
      end;
    end;

begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],tile) then exit;
  if not AAuf.TryArgToARV(2,8,8,[ARV_FixNum],blk) then exit;
  tile_obj:=TObject(pqword(tile.Head)^);
  if not (tile_obj is TMCA_Tile_List) then begin
    AufScpt.send_error('警告：第一个参数不能转化为TMCA_Tile_List对象，代码未执行。');exit
  end;
  blk_obj:=TObject(pqword(blk.Head)^);
  if not (blk_obj is TChunk_Block) then begin
    AufScpt.send_error('警告：第二个参数不能转化为TChunk_Block对象，代码未执行。');exit
  end;

  //if not AAuf.TryArgToDWord(3,p1) then exit;
  //if not AAuf.TryArgToDWord(4,p2) then exit;
  //if not AAuf.TryArgToDWord(5,p3) then exit;

  case lowercase(AAuf.args[0]) of
    'tile.getbiomes':
      begin
        if not AAuf.CheckArgs(4) then begin AufScpt.send_error('getbiomes需要3个参数，投影未执行。');exit end;
        if not AAuf.TryArgToDWord(3,floor) then exit;
        if (floor<0) or (floor>255) then begin AufScpt.send_error('getbiomes的p1需要在0-255范围内，投影未执行。');exit end;
        (tile_obj as TMCA_Tile_List).Projection(blk_obj as TChunk_Block,'biomes',floor);
      end;
    'tile.getclip':
      begin
        if not AAuf.CheckArgs(4) then begin AufScpt.send_error('getclip需要3个参数，投影未执行。');exit end;
        if not AAuf.TryArgToDWord(3,floor) then exit;
        if (floor<0) or (floor>255) then begin AufScpt.send_error('getclip的p1需要在0-255范围内，投影未执行。');exit end;
        (tile_obj as TMCA_Tile_List).Projection(blk_obj as TChunk_Block,'clip',floor);
      end;
    'tile.getbelow':
      begin
        if not AAuf.CheckArgs(4) then begin AufScpt.send_error('getbelow需要至少3个参数，投影未执行。');exit end;
        if not AAuf.TryArgToDWord(3,floor) then exit;
        if (floor<0) or (floor>255) then begin AufScpt.send_error('getbelow的p1需要在0-255范围内，投影未执行。');exit end;
        case AAuf.ArgsCount of
          4:SetSelectionRule(0,0);
          6:SetSelectionRule(4,5);
          else begin
            AufScpt.send_error('getbelow需要3或5个参数，投影未执行。');exit
          end;
        end;
        (tile_obj as TMCA_Tile_List).Projection(blk_obj as TChunk_Block,'below',floor,nil);
      end;
    'tile.getabove':
      begin
        if not AAuf.CheckArgs(4) then begin AufScpt.send_error('getabove需要至少3个参数，投影未执行。');exit end;
        if not AAuf.TryArgToDWord(3,floor) then exit;
        if (floor<0) or (floor>255) then begin AufScpt.send_error('getabove的p1需要在0-255范围内，投影未执行。');exit end;
        case AAuf.ArgsCount of
          4:SetSelectionRule(0,0);
          6:SetSelectionRule(4,5);
          else begin
            AufScpt.send_error('getabove需要3或5个参数，投影未执行。');exit
          end;
        end;
        (tile_obj as TMCA_Tile_List).Projection(blk_obj as TChunk_Block,'above',floor,nil);
      end;
    'tile.getheight':(tile_obj as TMCA_Tile_List).Projection(blk_obj as TChunk_Block,'height');
    'tile.getsurface':(tile_obj as TMCA_Tile_List).Projection(blk_obj as TChunk_Block,'surface');
    'tile.gettop':
      begin
        case AAuf.ArgsCount of
          3:SetSelectionRule(0,0);
          5:SetSelectionRule(3,4);
          else begin
            AufScpt.send_error('gettop需要2或4个参数，投影未执行。');exit
          end;
        end;
        (tile_obj as TMCA_Tile_List).Projection(blk_obj as TChunk_Block,'top',floor,nil);
      end;
    'tile.getrealheight':
      begin
        case AAuf.ArgsCount of
          3:SetSelectionRule(0,0);
          5:SetSelectionRule(3,4);
          else begin
            AufScpt.send_error('getrealheight需要2或4个参数，投影未执行。');exit
          end;
        end;
        (tile_obj as TMCA_Tile_List).Projection(blk_obj as TChunk_Block,'realheight',floor,nil);
      end;
    'tile.getdensity':
      begin
        case AAuf.ArgsCount of
          3:SetSelectionRule(0,0);
          5:SetSelectionRule(3,4);
          else begin
            AufScpt.send_error('getdensity需要2或4个参数，投影未执行。');exit
          end;
        end;
        (tile_obj as TMCA_Tile_List).Projection(blk_obj as TChunk_Block,'realdensity',floor,nil);
      end;
    else assert(false,'tile.get*函数case错误。');
  end;

end;

procedure Func_newEnts(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TEntities.Create;
  pqword(arv.Head)^:=qword(obj);
end;
procedure Func_freeEnts(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TEntities) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TEntities对象，未能正常释放对象。');
      exit
    end;
  (obj as TEntities).Free;
end;
procedure Func_clearEnts(Sender:TObject);//xxx $8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TEntities) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TEntities对象，未能正常清空对象。');
      exit
    end;
  (obj as TEntities).Clear;
end;
procedure Func_extractEnts(Sender:TObject);//xxx $8[],$8[]
var AufScpt:TAufScript;
    AAuf:TAuf;
    ents,tree:TAufRamVar;
    ents_obj,tree_obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],ents) then exit;
  if not AAuf.TryArgToARV(2,8,8,[ARV_FixNum],tree) then exit;
  ents_obj:=TObject(pqword(ents.Head)^);
  if not (ents_obj is TEntities) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TEntities对象，代码未执行。');
      exit
    end;
  tree_obj:=TObject(pqword(tree.Head)^);
  if not (tree_obj is TATree) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TATree对象，代码未执行。');
      exit
    end;
  try
    (ents_obj as TEntities).LoadFromTree(tree_obj as TAtree);
  except
    (tree_obj as TATree).PrintJSON('error.json');
  end;
end;
procedure Func_Ents2Csv(Sender:TObject);//xxx $8[],filename
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
    filename:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  if not AAuf.TryArgToString(2,filename) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TEntities) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TEntities对象，代码未执行。');
      exit
    end;
  (obj as TEntities).SaveToCSV(filename+'.csv');
end;
procedure Func_Ents2Shp(Sender:TObject);//xxx $8[],filename
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
    filename:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  if not AAuf.TryArgToString(2,filename) then exit;
  obj:=TObject(pqword(arv.Head)^);
  if not (obj is TEntities) then
    begin
      AufScpt.send_error('警告：第一个参数不能转化为TEntities对象，代码未执行。');
      exit
    end;
  (obj as TEntities).SaveAsShp(filename);
end;



procedure Func_MCA_GeoFormatting(Sender:TObject);//geof mca_file_name dir
var AufScpt:TAufScript;
    AAuf:TAuf;
    filename,dir,mode:string;
    chunkN,po,altitude,bindex:integer;
    tmp_tile:TMCA_Tile;
    block_tile_list:TMCA_Tile_List;
    ents:TEntities;
    mca:TMCA_Stream;
    chunk:TChunk_Stream;
    tree:TATree;
    blocks:TChunk_Block;
    sel:TSelectionRule;
    tmpBool:boolean;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToString(1, filename) then exit;
  if not AAuf.TryArgToString(2, dir) then exit;
  if AAuf.ArgsCount>3 then begin
    if not AAuf.TryArgToStrParam(3,['top','surface','clip','above','below','density','height','realheight','biomes'],false,mode) then exit;
  end else mode:='below';
  if AAuf.ArgsCount>4 then begin
    if not AAuf.TryArgToLong(4,altitude) then exit;
  end else altitude:=65;

  if filename='' then begin
    AufScpt.send_error('警告：文件名不能为空，代码未执行。');exit
  end;

  mca:=TMCA_Stream.Create;
  chunk:=TChunk_Stream.Create;
  tree:=TATree.Create;
  blocks:=TChunk_Block.Create;

  sel:=TSelectionRule.Create;
  //sel.AddBlock(473);//这是MC1.6.4 ICBCRCGTFR-nofr-NAM整合包中的剩余热量方块

  block_tile_list:=TMCA_Tile_List.Create;
  ents:=TEntities.Create;

  tmpBool:=false;
  mca.LoadFromFile(filename);
  for chunkN:=0 to 1023 do
    begin
      Application.ProcessMessages;
      try
        if not mca.ChunkAvailable(chunkN) then continue;
        if not chunk.LoadFromMCA(chunkN,mca) then continue;
        tree.Clear;
        chunk.Decode(tree);
        blocks.LoadFromTree(tree, nil);

        //重复往sel中增加，暂时的作法，之后重写selectition
        //bindex:=defaultBlocks.FindBlockId('minecraft:pointed_dripstone');
        //if bindex>=0 then sel.AddBlock(bindex);
        //if defaultBlocks.FindBlockId('minecraft:pointed_dripstone')>0 then begin
        //  if not tmpBool then AufScpt.writeln(Format('file: %s, chunk: %d',[filename,chunkN]));
        //  tmpBool:=true;
        //end;

        //block_tile_list.GetChunkPlan(blocks,mode,altitude,Byte(smExclude),sel);
        //block_tile_list.GetChunkPlan(blocks,mode,altitude,Byte(smJust),sel);

        //block_tile_list.GetChunkPlan(blocks,'above',65,Byte(smExclude),sel);
        //block_tile_list.GetChunkPlan(blocks,'clip',-59,Byte(smExclude),sel);
        //block_tile_list.GetChunkPlan(blocks,'biomes',54,Byte(smExclude),sel);
        //height_tile_list.GetChunkPlan(blocks,'realheight',0,Byte(smExclude),sel);
        ents.LoadFromTree(tree);
      except
        AufScpt.writeln('警告：mca['+IntToStr(mca.x)+','+IntToStr(mca.z)+'].chunk['+IntToStr(chunkN)+']读取失败。');
        //tree.JsonFileMode:=jfmAnalysis;
        //tree.PrintJSON('error_tree.json');
        //tree.JsonFileMode:=jfmStored;
        //break;
      end;
    end;
  //AufScpt.writeln(Format('number of entities: %d',[ents.Count]));

  filename:=ExtractFileName(filename);
  if pos('.mca',filename)=length(filename)-3 then delete(filename,length(filename)-3,4);
  //block_tile_list.SaveAsTiff(dir+'\'+filename+Format('_%s[%d]',[mode,altitude]));
  //height_tile_list.SaveAsTiff(dir+'\'+filename+'_height');
  ents.SaveAsShp(dir+'\'+filename+'_entities');

  ents.Free;
  block_tile_list.Free;
  sel.Free;
  blocks.Free;
  tree.Free;
  chunk.Free;
  mca.Free;

end;


procedure Func_newWorld(Sender:TObject); //world.new @w, path
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    obj:TObject;
    pathname:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1, 8, 8, [ARV_FixNum], arv) then exit;
  if not AAuf.TryArgToString(2, pathname) then exit;
  obj:=TMC_World.Create(pathname);
  obj_to_arv(obj, arv);
end;

procedure Func_readWorld(Sender:TObject); //world.read @w
var AufScpt:TAufScript;
    AAuf:TAuf;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToObject(1, TMC_World, obj) then exit;
  (obj as TMC_World).ReadWorld;
end;

procedure Func_saveWorld(Sender:TObject); //world.save @w
var AufScpt:TAufScript;
    AAuf:TAuf;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToObject(1, TMC_World, obj) then exit;
  (obj as TMC_World).SaveToPath;
end;

procedure Func_delWorld(Sender:TObject); //world.del @w
var AufScpt:TAufScript;
    AAuf:TAuf;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToObject(1, TMC_World, obj) then exit;
  (obj as TMC_World).Free;
end;

procedure Func_setWorldProjection(Sender:TObject); //world.setprj @w, prj
var AufScpt:TAufScript;
    AAuf:TAuf;
    obj:TObject;
    prj:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1, TMC_World, obj) then exit;
  if not AAuf.TryArgToStrParam(2, ['clip','above','below','top','surface','density'], false, prj) then exit;
  (obj as TMC_World).DisplaySetting.Projection:=prj;
end;

procedure Func_setWorldClipfloor(Sender:TObject); //world.setfloor @w, floor
var AufScpt:TAufScript;
    AAuf:TAuf;
    obj:TObject;
    floor:LongInt;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1, TMC_World, obj) then exit;
  if not AAuf.TryArgToLong(2, floor) then exit;
  (obj as TMC_World).DisplaySetting.ClipFloor:=floor;
end;

procedure Func_setWorldDimension(Sender:TObject); //world.setdim @w, overworld/nether/end
var AufScpt:TAufScript;
    AAuf:TAuf;
    obj:TObject;
    dimension:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1, TMC_World, obj) then exit;
  if not AAuf.TryArgToStrParam(2, ['overworld','over','nether','thenether','end','theend'], false, dimension) then exit;
  case lowercase(dimension) of
      'overworld', 'over':      (obj as TMC_World).DisplaySetting.Dimension:=wdOverWorld;
      'nether',    'thenether': (obj as TMC_World).DisplaySetting.Dimension:=wdTheNether;
      'end',       'theend':    (obj as TMC_World).DisplaySetting.Dimension:=wdTheEnd;
  end;
end;

procedure Func_setWorldSave(Sender:TObject); //world.setsave @w, json/chk on/off
var AufScpt:TAufScript;
    AAuf:TAuf;
    obj:TObject;
    mode,onoff:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToObject(1, TMC_World, obj) then exit;
  if not AAuf.TryArgToStrParam(2, ['json','chk'], false, mode) then exit;
  if not AAuf.TryArgToStrParam(3, ['on','off'], false, onoff) then exit;
  case lowercase(mode) of
      'json':case lowercase(onoff) of
          'on':(obj as TMC_World).WorldSetting.SaveJson:=true;
          'off':(obj as TMC_World).WorldSetting.SaveJson:=false;
      end;
      'chk' :case lowercase(onoff) of
          'on':(obj as TMC_World).WorldSetting.SaveChk:=true;
          'off':(obj as TMC_World).WorldSetting.SaveChk:=false;
      end;
  end;
end;

procedure TFormMain.AufInit(scpt:TAufScript);
begin

  WITH scpt DO BEGIN
    //InternalFuncDefine;
    add_func('about',@Func_about,'','当前MCA Reader的版本信息');
    add_func('mapviewer',@Func_MapViewer,'','打开MapViewer');

    add_func('palette.view.block',@Func_viewBlockPalette,'','显示方块色板');
    add_func('palette.view.biome',@Func_viewBiomePalette,'','显示群系色板');

    add_func('mca.new',@Func_newMCA,'arv','创建一个mca内存，并将指针保存在arv',TMCA_Stream);
    add_func('mca.free',@Func_freeMCA,'arv','释放arv指向的mca内存');
    add_func('mca.load',@Func_loadMCA,'arv,filename','加载mca文件到mca内存');
    add_func('mca.no_chunk?',@Func_DoesMCAHasNotChunk,'arv,chunkNo,:label','如果mca没有指定区块则跳转至label');

    add_func('chunk.new',@Func_newChunk,'arv','创建一个chunk内存，并将指针保存在arv',TChunk_Stream);
    add_func('chunk.free',@Func_freeChunk,'arv','释放arv指向的chunk内存');
    add_func('chunk.load',@Func_loadChunk,'arv,mca,chunkNo','从mca内存中提取第chunkNo个区块');
    add_func('chunk.loadfromdat',@Func_loadChunkFromDat,'arv,dat_file','从dat文件中提取NBT格式');
    add_func('chunk.decode',@Func_decodeChunk,'arv,tree','将arv指向的chunk内存中的NBT数据解析到tree中');

    add_func('tree.new',@Func_newTree,'arv','创建一个tree结构，并将指针保存在arv',TATree);
    add_func('tree.free',@Func_freeTree,'arv','释放arv指向的tree结构');
    add_func('tree.clear',@Func_clearTree,'arv','清空arv指向的tree结构');
    add_func('tree.info',@Func_infoTree,'arv','查看arv指向的tree结构目录');
    add_func('tree.to_json',@Func_Tree2Json,'arv,filename[,opt]','将arv指向的tree结构内容导出json到filename，opt="a"为分析模式');
    add_func('tree.has_palette?',@Func_DoesTreeHasPalette,'arv,:label','如果tree中的区块方块有Palette属性则跳转至label');
    add_func('tree.has_heightmaps?',@Func_DoesTreeHasHeightMaps,'arv,:label','如果tree中的区块方块有HeightMaps属性则跳转至label');

    add_func('block.new',@Func_newBlock,'arv','创建一个block内存，并将指针保存在arv',TChunk_Block);
    add_func('block.free',@Func_freeBlock,'arv','释放arv指向的block内存');
    add_func('block.extract',@Func_extractBlock,'arv,tree','从tree中提取方块信息到arv指向的block内存');
    add_func('block.to_txt',@Func_Block2Txt,'arv','将arv指向的block内存导出到txt文件中');
    add_func('block.to_chk',@Func_Block2Chunk,'arv','将arv指向的block内存导出到chk文件中');
    add_func('block.heightmap.to_txt',@Func_BlockHeightMap2Txt,'arv','将arv指向的block内存中的高度图导出到chk文件中');

    add_func('tile.new',@Func_newTile,'arv','创建一个tile列表，并将指针保存在arv',TMCA_Tile_List);
    add_func('tile.free',@Func_freeTile,'arv','释放arv指向的tile列表');
    add_func('tile.getbiomes',@Func_getTile,'arv,blk,floor','从blk指向的block内存中解析地图切片');
    add_func('tile.getclip',@Func_getTile,'arv,blk,floor','从blk指向的block内存中解析地图切片');
    add_func('tile.gettop',@Func_getTile,'arv,blk[,sel,mode]','从blk指向的block内存中解析顶视方块');
    add_func('tile.getbelow',@Func_getTile,'arv,blk,floor[,sel,mode]','从blk指向的block内存中解析断面俯视');
    add_func('tile.getabove',@Func_getTile,'arv,blk,floor[,sel,mode]','从blk指向的block内存中解析断面仰视');
    add_func('tile.getsurface',@Func_getTile,'arv,blk','从blk指向的block内存中解析表面方块');
    add_func('tile.getheight',@Func_getTile,'arv,blk','从blk指向的block内存中解析表面高度');
    add_func('tile.getrealheight',@Func_getTile,'arv,blk[,sel,mode]','从blk指向的block内存中解析顶视高度');
    add_func('tile.getdensity',@Func_getTile,'arv,blk[,sel,mode]','从blk指向的block内存中解析方块密度');
    //add_func('tile.getcave',@Func_getTile,'arv,blk,floor','从blk指向的block内存中解析洞穴地图');
    add_func('tile.to_bmp',@Func_Tile2Bmp,'arv,filename','将arv指向的tile列表导出到bmp图片');
    add_func('tile.to_tif',@Func_Tile2Tiff,'arv,filename','将arv指向的tile列表导出到tif图片');

    add_func('ents.new',@Func_newEnts,'arv','创建一个ents列表，并将指针保存在arv',TEntities);
    add_func('ents.free',@Func_freeEnts,'arv','释放arv指向的ents列表');
    add_func('ents.clear',@Func_clearEnts,'arv','清空arv指向的ents列表');
    add_func('ents.extract',@Func_extractEnts,'arv,tree','从tree中提取实体信息到arv指向的ents列表');
    add_func('ents.to_csv',@Func_Ents2Csv,'arv,tree','从tree中提取实体信息到arv指向的ents列表');
    add_func('ents.to_shp',@Func_Ents2Shp,'arv,tree','从tree中提取实体信息到arv指向的ents列表');


    //整合功能
    add_func('geof',@Func_MCA_GeoFormatting,'filename,dir','将mca文件转化为同名的tif文件和shp文件');

    add_func('world.new',@Func_newWorld,'@w, filename','导入存档');
    add_func('world.read',@Func_readWorld,'@w','读取存档');
    add_func('world.save',@Func_saveWorld,'@w','按设置导出存档');
    add_func('world.del',@Func_delWorld,'@w','按设置导出存档');
    add_func('world.setprj',@Func_setWorldProjection,'@w, prj','设置存档的三维到二维的投影');
    add_func('world.setfloor',@Func_setWorldClipfloor,'@w, floor','设置存档的三维到二维的特征层');
    add_func('world.setdim',@Func_setWorldDimension,'@w, overworld/nether/end','设置存档读取维度');
    add_func('world.setsave',@Func_setWorldSave,'@w, savefile, on/off','设置存档存档文件保存与否');


    //临时存在
    add_func('read_tile',@Func_MCA2Tile,'filename[,x,z]','从mca文件到Tile');
    add_func('tile_export',@Func_TileList_Export,'filename','将方块平面图保存到filename');
    add_func('ents_export',@Func_Entities_Export,'filename','将实体列表保存到filename');

  END;

end;

procedure TFormMain.FormCreate(Sender: TObject);
begin

  Self.Frame_AufScript1.AufGenerator;
  AufInit(Self.Frame_AufScript1.Auf.Script);
  FormViewer:=TFormViewer.Create(Application);
  Position:=poScreenCenter;

end;

procedure TFormMain.FormResize(Sender: TObject);
begin
  Self.Frame_AufScript1.FrameResize(nil);
end;

procedure TFormMain.MenuItem_Option_AboutClick(Sender: TObject);
begin
  FormMain.Frame_AufScript1.Auf.Script.ClearScreen;
  Application.ProcessMessages;
  Func_About(FormMain.Frame_AufScript1.Auf.Script);
end;

procedure TFormMain.MenuItem_Option_HelpClick(Sender: TObject);
begin
  FormMain.Frame_AufScript1.Auf.Script.ClearScreen;
  Application.ProcessMessages;
  FormMain.Frame_AufScript1.Auf.Script.command('help');
end;

initialization

MCA_Tile_List:=TMCA_Tile_List.Create;
Entities_List:=TEntities.Create;

end.

