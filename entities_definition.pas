unit entities_definition;

{$mode objfpc}{$H+}
{$inline on}

interface

uses
  Classes, SysUtils, Apiglio_Useful, apiglio_tree;

type
  TEntityUnit=class
    id:string;
    rotation:record
      h,v:single;
    end;
    motion,pos:record
      x,y,z:double;
    end;
    note:string;
  public
    function to_csv_line:string;
  end;

  TEntities=class(TList)
  public
    LoadEntities:boolean;
    LoadTileEnts:boolean;
  public
    function AddEntity(ent_id:string):TEntityUnit;
    procedure SaveToCSV(filename:string);
    procedure SaveAsShp(filename_without_ext:string);
  protected
    function OnlyOneChunk(tree:TATree):boolean;inline;
    function ExtractEntities_164(tree:TATree):boolean;
    function ExtractBlockEntities_164(tree:TATree):boolean;

  public
    function LoadFromTree(tree:TATree):boolean;
  public
    constructor Create;
    destructor Destroy;override;
    class function AufTypeName:String;
  end;


implementation
uses Apiglio_ShapeFile, Apiglio_Geo;


function TEntityUnit.to_csv_line:string;
begin
  result:=id+','+FloatToStrF(pos.x,ffNumber,0,9)+','
                +FloatToStrF(pos.z,ffNumber,0,9)+','
                +FloatToStrF(pos.y,ffNumber,0,9)+','
                +FloatToStrF(rotation.h,ffNumber,0,9)+','
                +FloatToStrF(rotation.v,ffNumber,0,9)+',';
end;

function TEntities.AddEntity(ent_id:string):TEntityUnit;
begin
  result:=TEntityUnit.Create;
  result.id:=ent_id;
  Self.Add(result);
end;
procedure TEntities.SaveToCSV(filename:string);
var tmp:text;
    pi:integer;
    ent:TEntityUnit;
begin
  try
    assignfile(tmp,filename);
    rewrite(tmp);
    writeln(tmp,'ent_name,x,y,z,rh,rv');
    for pi:=0 to Self.Count-1 do
      begin
        ent:=TEntityUnit(Self.Items[pi]);
        writeln(tmp,ent.to_csv_line);
      end;
    closefile(tmp);
  except
  end;
end;

procedure TEntities.SaveAsShp(filename_without_ext:string);
var fid:integer;
    tmpSHP:TShapeFile;
    fea:TAGeoPoint;
begin
  tmpSHP:=TShapeFile.Create(shpPoint);
  tmpSHP.AddField('ent_name',gptChar);//1
  tmpSHP.AddField('rotation',gptFloat);//2
  tmpSHP.AddField('elevation',gptFloat);//3
  tmpSHP.AddField('note',gptChar);//4

  for fid:=0 to Self.Count-1 do
    begin
      fea:=TAGeoPoint.Create;
      fea.Point.x:=TEntityUnit(Self.Items[fid]).pos.x;
      fea.Point.y:=-TEntityUnit(Self.Items[fid]).pos.z;
      fea.Point.z:=TEntityUnit(Self.Items[fid]).pos.y;
      fea.Char[1]:=TEntityUnit(Self.Items[fid]).id;
      fea.Float[2]:=TEntityUnit(Self.Items[fid]).rotation.h;
      fea.Float[3]:=TEntityUnit(Self.Items[fid]).pos.y;
      fea.Char[4]:=TEntityUnit(Self.Items[fid]).note;
      {
      fea.Point.x:=0;
      fea.Point.y:=0;
      fea.Point.z:=0;
      //fea.Char[1]:='de';
      fea.Float[2]:=single(0);
      }
      tmpSHP.AddFeature(fea);
    end;

  tmpSHP.SaveToFile(filename_without_ext);
end;

function TEntities.ExtractEntities_164(tree:TATree):boolean;
var tmp:TAListUnit;
    node:TATreeUnit;
    px,py,pz,mx,my,mz:double;
    rh,rv:single;
    ent_id:string;
begin

  tree.CurrentInto(tree.root.Achild.first.obj as TATreeUnit);
  tree.CurrentInto('Level'); //21w39a展开了Level层
  if not tree.CurrentInto('Entities') then if not tree.CurrentInto('entities') then exit; //21w43a重命名Entities为entities
  tmp:=tree.Current.AChild.first;
  while tmp<>nil do
    begin
      tree.CurrentInto(tmp.obj as TATreeUnit);

      tree.CurrentInto('id');
      ent_id:=tree.Current.AString;
      tree.CurrentOut;

      tree.CurrentInto('Pos');
      node:=tree.Current.AChild.first.obj as TATreeUnit;
      px:=node.RDouble;
      node:=tree.Current.AChild.first.next.obj as TATreeUnit;
      py:=node.RDouble;
      node:=tree.Current.AChild.first.next.next.obj as TATreeUnit;
      pz:=node.RDouble;
      tree.CurrentOut;

      tree.CurrentInto('Motion');
      node:=tree.Current.AChild.first.obj as TATreeUnit;
      mx:=node.RDouble;
      node:=tree.Current.AChild.first.next.obj as TATreeUnit;
      my:=node.RDouble;
      node:=tree.Current.AChild.first.next.next.obj as TATreeUnit;
      mz:=node.RDouble;
      tree.CurrentOut;

      tree.CurrentInto('Rotation');
      node:=tree.Current.AChild.first.obj as TATreeUnit;
      rh:=node.RFloat;
      node:=tree.Current.AChild.first.next.obj as TATreeUnit;
      rv:=node.RFloat;
      tree.CurrentOut;

      tree.CurrentOut;

      with AddEntity(ent_id) do
        begin
          rotation.h:=rh;
          rotation.v:=rv;
          pos.x:=px;
          pos.y:=py;
          pos.z:=pz;
          motion.x:=mx;
          motion.y:=my;
          motion.z:=mz;
        end;

      tmp:=tmp.next;
    end;


end;

function TEntities.ExtractBlockEntities_164(tree:TATree):boolean;
var tmp:TAListUnit;
    node:TATreeUnit;
    px,py,pz:Integer;
    ent_id:string;
    extra_note:string;

begin
    result:=false;
    tree.CurrentInto(tree.root.Achild.first.obj as TATreeUnit);
    if tree.CurrentInto('Level') then begin
        if not tree.CurrentInto('TileEntities') then raise Exception.Create('no Level.TileEntities');
    end else begin
        //21w39a展开了Level层
        if not tree.CurrentInto('block_entities') then raise Exception.Create('no block_entities');
    end;
    tmp:=tree.Current.AChild.first;
    while tmp<>nil do begin
        tree.CurrentInto(tmp.obj as TATreeUnit);

        tree.CurrentInto('id');
        ent_id:='';
        ent_id:=tree.Current.AString;
        tree.CurrentOut;

        tree.CurrentInto('x');
        px:=tree.Current.RInt;
        tree.CurrentOut;

        tree.CurrentInto('y');
        py:=tree.Current.RInt;
        tree.CurrentOut;

        tree.CurrentInto('z');
        pz:=tree.Current.RInt;
        tree.CurrentOut;

        //临时的读取结构
        if ent_id='minecraft:mob_spawner' then begin
            node:=tree.Current;
            tree.CurrentInto('SpawnData');
            tree.CurrentInto('entity');
            tree.CurrentInto('id');
            if tree.Current.NbtType = NBT_String then
                extra_note:=tree.Current.AString;
            tree.CurrentInto(node);
        end;
        if extra_note='' then extra_note:=' ';

        tree.CurrentOut;

        with AddEntity(ent_id) do begin
            rotation.h:=0;
            rotation.v:=0;

            pos.x:=px;
            pos.y:=py;
            pos.z:=pz;
            motion.x:=0;
            motion.y:=0;
            motion.z:=0;

            note:=extra_note;
        end;

        tmp:=tmp.next;
    end;
end;

function TEntities.OnlyOneChunk(tree:TATree):boolean;inline;
begin
  if tree.root.Achild.count<>1 then result:=false else result:=true;
end;
function TEntities.LoadFromTree(tree:TATree):boolean;
begin
  result:=false;
  if not OnlyOneChunk(tree) then exit;
  if LoadEntities then ExtractEntities_164(tree);
  if LoadTileEnts then ExtractBlockEntities_164(tree);
  result:=true;
end;

constructor TEntities.Create;
begin
  inherited Create;
  LoadEntities:=true;
  LoadTileEnts:=true;
end;

destructor TEntities.Destroy;
begin
  while Self.Count<>0 do
    begin
      TEntityUnit(Self.Items[0]).Free;
      Self.Delete(0);
    end;
  inherited Destroy;
end;

class function TEntities.AufTypeName:String;
begin
  result:='ents';
end;

end.

