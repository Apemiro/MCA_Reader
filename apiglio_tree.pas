//{$define insert}
//这里widestring、utf8string和string混用如同地狱

unit Apiglio_Tree;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, Windows{$ifndef Insert},Apiglio_Useful{$endif};

type
  NBT=(
    NBT_End=0,    NBT_Byte=1,    NBT_Short=2,      NBT_Int=3,
    NBT_Long=4,   NBT_Float=5,   NBT_Double=6,     NBT_ByteArray=7,
    NBT_String=8, NBT_List=9,    NBT_Compound=10,  NBT_IntArray=11,
    NBT_LongArray=12
  );

  TNBT_Adapter=record
    case TreeTypeJson:byte of
      0:(vByte:byte);
      1:(vShort:word);
      2:(vInt:dword);
      3:(vLong:qword);
      4:(vFloat:single);
      5:(vDouble:double);
      10:(vuByte:byte);
      11:(vuShort:word);
      12:(vuInt:dword);
      13:(vuLong:qword);
    end;

  //pTAListUnit=^TAListUnit;
  TAListUnit=class
  public
    prev,next:TAListUnit;
    obj:TObject;
    constructor Create;
  end;

  TAList=class
  public
    first,last:TAListUnit;
    count:longint;
    constructor Create;
    procedure Add(obj:TObject);
    procedure Remove(obj:TObject);
  end;

  //pTATreeUnit=^TATreeUnit;
  TATreeUnit=class(TObject)
    FOwner:TObject;
  public
    name:utf8string;
    Aparent:TATreeUnit;
    Achild:TAList;

    stream:TMemoryStream;//用getmem淘汰掉以提高速度（）
    ptr:Pointer;//新的存储方式
    size:word;//新的存储方式

    NbtType:NBT;
    ListType:byte;
    ListId:dword;
  protected
    function GetByte:byte;
    function GetShort:smallint;
    function GetInt:longint;
    function GetLong:int64;
    function GetFloat:single;
    function GetDouble:double;
    function GetString:string;
    function GetByteArray(index:dword):byte;
    function GetIntArray(index:dword):longint;
    function GetLongArray(index:dword):int64;

    function GetReverseByte:byte;
    function GetReverseShort:smallint;
    function GetReverseInt:longint;
    function GetReverseLong:int64;
    function GetReverseFloat:single;
    function GetReverseDouble:double;
    function GetReverseString:string;
    function GetReverseByteArray(index:dword):byte;
    function GetReverseIntArray(index:dword):longint;
    function GetReverseLongArray(index:dword):int64;

  public
    property AByte:byte read GetByte;
    property AShort:smallint read GetShort;
    property AInt:longint read GetInt;
    property ALong:int64 read GetLong;
    property AFloat:single read GetFloat;
    property ADouble:double read GetDouble;
    property AString:string read GetString;
    property AByteArray[index:dword]:byte read GetByteArray;
    property AIntArray[index:dword]:longint read GetIntArray;
    property ALongArray[index:dword]:int64 read GetLongArray;

    property RByte:byte read GetReverseByte;
    property RShort:smallint read GetReverseShort;
    property RInt:longint read GetReverseInt;
    property RLong:int64 read GetReverseLong;
    property RFloat:single read GetReverseFloat;
    property RDouble:double read GetReverseDouble;
    property RString:string read GetReverseString;
    property RByteArray[index:dword]:byte read GetReverseByteArray;
    property RIntArray[index:dword]:longint read GetReverseIntArray;
    property RLongArray[index:dword]:int64 read GetReverseLongArray;


  public
    procedure Print(level:integer=0);
    procedure PrintJSON(level:integer=0);
    procedure PrintOne;
  public
    constructor Create(AOwner:TObject);
    destructor Destroy;override;
  end;

  TJsonFileMode=(jfmStored=0,jfmAnalysis=1,jfmEntries=2);
  TATree=class
    root:TATreeUnit;
    Current:TATreeUnit;
    IO_message:procedure(Sender:TObject;s:string);
    JSON_file:text;
    JsonFileMode:TJsonFileMode;
    Debug:boolean;
  public
    property TreeRoot:TATreeUnit read root;
    constructor Create;
    class function AufTypeName:String;

    procedure Clear;
    procedure AddUnit(Varname:widestring;AStream:TMemoryStream;AType:NBT);

    procedure AddByte(key:string;value:byte);
    procedure AddShort(key:string;value:smallint);
    procedure AddInt(key:string;value:longint);
    procedure AddLong(key:string;value:int64);
    procedure AddFloat(key:string;value:single);
    procedure AddDouble(key:string;value:double);
    function AddString(key:string;size:word):pchar;
    function AddByteArray(key:string;size:dword):pbyte;
    function AddIntArray(key:string;size:dword):plong;
    function AddLongArray(key:string;size:dword):pint64;



    function CurrentInto(varname:widestring):boolean;
    procedure CurrentInto(varname:widestring);
    function ChildExists(varname:widestring):boolean;
    procedure CurrentInto(ATreeUnit:TATreeUnit);
    procedure CurrentOut;
    procedure PrintJSON(filename:string='tree.json');



  end;

//var
//  ATree:TATree;

procedure de_cmd_writeln(Sender:TObject;str:string);
procedure de_gui_writeln(Sender:TObject;str:string);
function NBT_Typist(inp:NBT):string;
function NBT_FullTypist(inp:NBT):string;
function level_space(level:integer):string;

function EndianReverse(num:qword):qword;
function EndianReverse(num:dword):dword;
function EndianReverse(num:word):word;

function NbtLong_to_s(inp:int64):string;
function NbtInt_to_s(inp:longint):string;
function NbtShort_to_s(inp:smallint):string;
function NbtByte_to_s(inp:shortint):string;




implementation

function NbtLong_to_s(inp:int64):string;
begin
  str(inp,result);
end;
function NbtInt_to_s(inp:longint):string;
begin
  str(inp,result);
end;
function NbtShort_to_s(inp:smallint):string;
begin
  str(inp,result);
end;
function NbtByte_to_s(inp:shortint):string;
begin
  str(inp,result);
end;

//SwapEndian直接可以用这个
function EndianReverse(num:qword):qword;
begin
  result:=qword(0);
  for i:=1 to 8-1 do
    begin
      result:=result + num mod 256;
      num:=num shr 8;
      result:=result shl 8;
    end;
  result:=result+num;
end;
function EndianReverse(num:dword):dword;
begin
  result:=dword(0);
  for i:=1 to 4-1 do
    begin
      result:=result + num mod 256;
      num:=num shr 8;
      result:=result shl 8;
    end;
  result:=result+num;
end;
function EndianReverse(num:word):word;
begin
  result:=word(0);
  for i:=1 to 2-1 do
    begin
      result:=result + num mod 256;
      num:=num shr 8;
      result:=result shl 8;
    end;
  result:=result+num;
end;



{ TAListUnit }
constructor TAListUnit.Create;
begin
  inherited Create;
end;

{ TAList }
constructor TAList.Create;
begin
  inherited Create;
  Count:=0;
  First:=nil;
  Last:=nil
end;
procedure TAList.Add(obj:TObject);
var tmp:TAListUnit;
begin
  tmp:=TAListUnit.Create;
  tmp.obj:=obj;
  tmp.next:=nil;
  if last=nil then
    begin
      tmp.prev:=nil;
      first:=tmp;
    end
  else
    begin
      tmp.prev:=last;
      last.next:=tmp;
    end;
  last:=tmp;
  count:=count+1;
end;

procedure TAList.Remove(obj:TObject);
var tmp:TAListUnit;
begin
  tmp:=first;
  while tmp<>nil do
    begin
      if tmp.obj=obj then
        begin
          tmp.obj.free;
          if tmp.prev=nil then first:=tmp.next
          else tmp.prev.next:=tmp.next;
          if tmp.next=nil then last:=tmp.prev
          else tmp.next.prev:=tmp.prev;
          tmp.free;
          count:=count+1;
          exit;
        end;
      tmp:=tmp.next;
    end;
end;

{ TATreeUnit }
constructor TATreeUnit.Create(AOwner:TObject);
begin
  inherited Create;
  Achild:=TAList.Create;
  ListId:=0;
  ListType:=0;
  FOwner:=AOwner;
end;

destructor TATreeUnit.Destroy;
var tmp:TAListUnit;
begin
  tmp:=AChild.first;
  while tmp<>nil do
    begin
      (tmp.obj as TATreeUnit).Destroy;
      tmp:=tmp.next;
    end;
  freemem(ptr);
  AChild.Free;
  stream.Free;
  inherited Destroy;
end;

function TATreeUnit.GetByte:byte;
begin
  if Self.ptr=nil then exit;
  result:=pbyte(Self.ptr)^;
end;
function TATreeUnit.GetShort:smallint;
begin
  if Self.ptr=nil then exit;
  result:=psmallint(Self.ptr)^;
end;
function TATreeUnit.GetInt:longint;
begin
  if Self.ptr=nil then exit;
  result:=plong(Self.ptr)^;
end;
function TATreeUnit.GetLong:int64;
begin
  if Self.ptr=nil then exit;
  result:=pint64(Self.ptr)^;
end;
function TATreeUnit.GetFloat:single;
begin
  if Self.ptr=nil then exit;
  result:=psingle(Self.ptr)^;
end;
function TATreeUnit.GetDouble:double;
begin
  if Self.ptr=nil then exit;
  result:=pdouble(Self.ptr)^;
end;
function TATreeUnit.GetString:string;
var str:string;
begin
  if Self.ptr=nil then exit;
  str:=PChar(Self.ptr);
  while length(str)>Self.size do delete(str,Self.size+1,999);
  result:=str;
end;
function TATreeUnit.GetByteArray(index:dword):byte;
var p:pbyte;
begin
  if Self.ptr=nil then exit;
  p:=pbyte(Self.ptr);
  inc(p,index);
  result:=p^;
end;
function TATreeUnit.GetIntArray(index:dword):longint;
var p:plong;
begin
  if Self.ptr=nil then exit;
  p:=plong(Self.ptr);
  inc(p,index);
  result:=p^;
end;
function TATreeUnit.GetLongArray(index:dword):int64;
var p:pint64;
begin
  if Self.ptr=nil then exit;
  p:=pint64(Self.ptr);
  inc(p,index);
  result:=p^;
end;


function TATreeUnit.GetReverseByte:byte;
begin
  if Self.ptr=nil then exit;
  result:=pbyte(Self.ptr)^;
end;
function TATreeUnit.GetReverseShort:smallint;
begin
  if Self.ptr=nil then exit;
  result:=SwapEndian(psmallint(Self.ptr)^);
end;
function TATreeUnit.GetReverseInt:longint;
begin
  if Self.ptr=nil then exit;
  result:=SwapEndian(plong(Self.ptr)^);
end;
function TATreeUnit.GetReverseLong:int64;
begin
  if Self.ptr=nil then exit;
  result:=SwapEndian(pint64(Self.ptr)^);
end;
function TATreeUnit.GetReverseFloat:single;
var v:TNBT_Adapter;
begin
  v.vInt:=SwapEndian(AInt);
  result:=v.vFloat
end;
function TATreeUnit.GetReverseDouble:double;
var v:TNBT_Adapter;
begin
  v.vLong:=SwapEndian(ALong);
  result:=v.vDouble
end;
function TATreeUnit.GetReverseString:string;//is this necessary?
var str:string;
begin
  if Self.ptr=nil then exit;
  str:=PChar(Self.ptr);
  while length(str)>Self.size do delete(str,Self.size+1,999);
  result:=str;
end;
function TATreeUnit.GetReverseByteArray(index:dword):byte;
var p:pbyte;
begin
  if Self.ptr=nil then exit;
  p:=pbyte(Self.ptr);
  inc(p,index);
  result:=p^;
end;
function TATreeUnit.GetReverseIntArray(index:dword):longint;
var p:plong;
begin
  if Self.ptr=nil then exit;
  p:=plong(Self.ptr);
  inc(p,index);
  result:=SwapEndian(p^);
end;
function TATreeUnit.GetReverseLongArray(index:dword):int64;
var p:pint64;
begin
  if Self.ptr=nil then exit;
  p:=pint64(Self.ptr);
  inc(p,index);
  result:=SwapEndian(p^);
end;


procedure TATreeUnit.Print(level:integer=0);
var tmp:TAListUnit;
begin
  (FOwner as TATree).IO_message(Auf.Script,level_space(level)+Self.name+':'+NBT_typist(Self.NbtType));
  tmp:=AChild.first;
  while tmp<>nil do
    begin
      (tmp.obj as TATreeUnit).print(level+1);
      tmp:=tmp.next;
    end;

end;

procedure TATreeUnit.PrintJSON(level:integer=0);
var tmp:TAListUnit;
    value:TNBT_Adapter;
    str:widestring;
    ctmp:char;
    i:{dword}int64;
    ATree:TATree;

begin
  ATree:=(FOwner as TATree);
  if ATree.Debug then ATree.IO_message(Auf.Script,level_space(level)+name);
  writeln(ATree.JSON_file);
  write(ATree.JSON_file,level_space(level));
  if AParent=nil then
    begin
      IF ATree.JsonFileMode<>jfmStored THEN BEGIN
        write(ATree.JSON_file,NBT_FullTypist(NbtType)+'('+''''+name+''''+'):');
      END ELSE BEGIN
        write(ATree.JSON_file,'"'+name+'":');
      END;
    end
  {
  else if AParent=ATree.root then
    begin
      //
    end
  }
  else if AParent.NbtType=NBT_List then
    begin
      IF ATree.JsonFileMode<>jfmStored THEN BEGIN
        write(ATree.JSON_file,NBT_FullTypist(NbtType)+'('+'None'+'):');
      END;
    end
  else
    begin
      IF ATree.JsonFileMode<>jfmStored THEN BEGIN
      write(ATree.JSON_file,NBT_FullTypist(NbtType)+'('+''''+name+''''+'):');
      END ELSE BEGIN
      write(ATree.JSON_file,'"'+name+'":');
      END;
    end;
  IF ATree.JsonFileMode<>jfmStored THEN BEGIN
    case NbtType of
      NBT_Compound,NBT_List:
        begin
          if Achild.count in [0,1] then
            write(ATree.JSON_file,IntToStr(Achild.count)+' entry')
          else
            write(ATree.JSON_file,IntToStr(Achild.count)+' entries');
        end;
      NBT_LongArray,NBT_IntArray,NBT_ByteArray:
        begin
          write(ATree.JSON_file,'Array('+IntToStr(Self.size)+')');
        end;
    end
  END;
  if (NbtType=NBT_Compound) then
    begin
      write(ATree.JSON_file,'{');
    end
  else if (NbtType=NBT_List) or (NbtType=NBT_LongArray) or (NbtType=NBT_IntArray) or (NbtType=NBT_ByteArray) then
    begin
      write(ATree.JSON_file,'[');
    end
  else if (NbtType=NBT_String) then
    begin
      write(ATree.JSON_file,'"');
    end
  else
    begin
      //
    end;

  IF ATree.JsonFileMode<>jfmEntries THEN BEGIN
  IF {(stream=nil)and(NbtType<>NBT_List)and(NbtType<>NBT_Compound)}false THEN write(ATree.JSON_file,'unassigned')
  ELSE BEGIN
    if (stream<>nil) then stream.position:=0;
  case NbtType of
    NBT_Byte:
      begin
        write(ATree.JSON_file,RByte);
      end;
    NBT_Short:
      begin
        write(ATree.JSON_file,RShort);
      end;
    NBT_Int:
      begin
        write(ATree.JSON_file,RInt);
      end;
    NBT_Long:
      begin
        write(ATree.JSON_file,RLong);
      end;
    NBT_ByteArray:
      begin
        for i:=0 to size-1 do
          begin
            write(ATree.JSON_file,RByteArray[i]);
            if i<>size-1 then write(ATree.JSON_file,',');
          end;
      end;
    NBT_String:
      begin
        write(ATree.JSON_file,RString);
      end;
    NBT_Float:
      begin
        write(ATree.JSON_file,RFloat:6:6);
      end;
    NBT_Double:
      begin
        write(ATree.JSON_file,RDouble:9:9);
      end;
    NBT_List:
      begin
        ///
      end;
    NBT_Compound:
      begin
        ///
      end;
    NBT_IntArray:
      begin
        for i:=0 to size-1 do
          begin
            write(ATree.JSON_file,RIntArray[i]);
            if i<>size-1 then write(ATree.JSON_file,',');
          end;
      end;
    NBT_LongArray:
      begin
        for i:=0 to size-1 do
          begin
            write(ATree.JSON_file,RLongArray[i]);
            if i<>size-1 then write(ATree.JSON_file,',');
          end;
      end;
    else ;
  end;


  END;

  END;

  tmp:=AChild.first;
  while tmp<>nil do
    begin
      (tmp.obj as TATreeUnit).printJSON(level+1);
      tmp:=tmp.next;
      if tmp<>nil then write(ATree.JSON_file,',');
    end;


  if (NbtType=NBT_Compound) then
    begin
      if AChild.first<>nil then
        begin
          writeln(ATree.JSON_file);
          write(ATree.JSON_file,level_space(level));
        end;
      write(ATree.JSON_file,'}');
    end
  else if (NbtType=NBT_List) or (NbtType=NBT_LongArray) or (NbtType=NBT_IntArray) or (NbtType=NBT_ByteArray) then
    begin
      if AChild.first<>nil then
        begin
          writeln(ATree.JSON_file);
          write(ATree.JSON_file,level_space(level));
        end;
      write(ATree.JSON_file,']');
    end
  else if (NbtType=NBT_String) then
    begin
      write(ATree.JSON_file,'"');
    end
  else
    begin
      //
    end;
end;

procedure TATreeUnit.PrintOne;
begin
  (FOwner as TATree).IO_message(Auf.Script,NBT_Typist(Self.NbtType)+':'+Self.name);
end;

{ TATree }
constructor TATree.Create;
begin
  inherited Create;
  Self.root:=TATreeUnit.Create(Self);
  Self.Current:=root;
  Self.root.name:='Apiglio';
  Self.root.NbtType:=NBT_Compound;
  Self.Debug:=false;
end;
class function TATree.AufTypeName:String;
begin
  result:='tree';
end;
procedure TATree.Clear;
begin
  Self.root.Destroy;
  Self.root:=TATreeUnit.Create(Self);
  Self.root.name:='Apiglio';
  Self.root.NbtType:=NBT_Compound;
  Self.Current:=Self.root;
end;
procedure TATree.AddUnit(Varname:widestring;AStream:TMemoryStream;AType:NBT);
var tmp:TATreeUnit;
begin
  tmp:=TATreeUnit.Create(Self);
  tmp.NbtType:=AType;
  tmp.stream:=AStream;
  tmp.Aparent:=Self.Current;
  Self.Current.Achild.Add(tmp);
  tmp.name:=Varname;
end;


procedure TATree.AddByte(key:string;value:byte);
var tmp:TATreeUnit;
begin
  tmp:=TATreeUnit.Create(Self);
  tmp.NbtType:=NBT_Byte;
  tmp.size:=1;
  tmp.ptr:=getmem(tmp.size);
  pbyte(tmp.ptr)^:=value;
  tmp.Aparent:=Self.Current;
  Self.Current.Achild.Add(tmp);
  tmp.name:=key;
end;
procedure TATree.AddShort(key:string;value:smallint);
var tmp:TATreeUnit;
begin
  tmp:=TATreeUnit.Create(Self);
  tmp.NbtType:=NBT_Short;
  tmp.size:=2;
  tmp.ptr:=getmem(tmp.size);
  psmallint(tmp.ptr)^:=value;
  tmp.Aparent:=Self.Current;
  Self.Current.Achild.Add(tmp);
  tmp.name:=key;
end;
procedure TATree.AddInt(key:string;value:longint);
var tmp:TATreeUnit;
begin
  tmp:=TATreeUnit.Create(Self);
  tmp.NbtType:=NBT_Int;
  tmp.size:=4;
  tmp.ptr:=getmem(tmp.size);
  plong(tmp.ptr)^:=value;
  tmp.Aparent:=Self.Current;
  Self.Current.Achild.Add(tmp);
  tmp.name:=key;
end;
procedure TATree.AddLong(key:string;value:int64);
var tmp:TATreeUnit;
begin
  tmp:=TATreeUnit.Create(Self);
  tmp.NbtType:=NBT_Long;
  tmp.size:=8;
  tmp.ptr:=getmem(tmp.size);
  pint64(tmp.ptr)^:=value;
  tmp.Aparent:=Self.Current;
  Self.Current.Achild.Add(tmp);
  tmp.name:=key;
end;
procedure TATree.AddFloat(key:string;value:single);
var tmp:TATreeUnit;
begin
  tmp:=TATreeUnit.Create(Self);
  tmp.NbtType:=NBT_Float;
  tmp.size:=4;
  tmp.ptr:=getmem(tmp.size);
  psingle(tmp.ptr)^:=value;
  tmp.Aparent:=Self.Current;
  Self.Current.Achild.Add(tmp);
  tmp.name:=key;
end;
procedure TATree.AddDouble(key:string;value:double);
var tmp:TATreeUnit;
begin
  tmp:=TATreeUnit.Create(Self);
  tmp.NbtType:=NBT_Double;
  tmp.size:=8;
  tmp.ptr:=getmem(tmp.size);
  pdouble(tmp.ptr)^:=value;
  tmp.Aparent:=Self.Current;
  Self.Current.Achild.Add(tmp);
  tmp.name:=key;
end;
function TATree.AddString(key:string;size:word):pchar;
var tmp:TATreeUnit;
begin
  tmp:=TATreeUnit.Create(Self);
  tmp.NbtType:=NBT_String;
  tmp.size:=size;
  tmp.ptr:=getmem(tmp.size);
  tmp.Aparent:=Self.Current;
  Self.Current.Achild.Add(tmp);
  tmp.name:=key;
  result:=pchar(tmp.ptr);
end;
function TATree.AddByteArray(key:string;size:dword):pbyte;
var tmp:TATreeUnit;
begin
  tmp:=TATreeUnit.Create(Self);
  tmp.NbtType:=NBT_ByteArray;
  tmp.size:=size;
  tmp.ptr:=getmem(tmp.size);
  tmp.Aparent:=Self.Current;
  Self.Current.Achild.Add(tmp);
  tmp.name:=key;
  result:=pbyte(tmp.ptr);
end;
function TATree.AddIntArray(key:string;size:dword):plong;
var tmp:TATreeUnit;
begin
  tmp:=TATreeUnit.Create(Self);
  tmp.NbtType:=NBT_IntArray;
  tmp.size:=size;
  tmp.ptr:=getmem(tmp.size*4);
  tmp.Aparent:=Self.Current;
  Self.Current.Achild.Add(tmp);
  tmp.name:=key;
  result:=plong(tmp.ptr);
end;
function TATree.AddLongArray(key:string;size:dword):pint64;
var tmp:TATreeUnit;
begin
  tmp:=TATreeUnit.Create(Self);
  tmp.NbtType:=NBT_LongArray;
  tmp.size:=size;
  tmp.ptr:=getmem(tmp.size*8);
  tmp.Aparent:=Self.Current;
  Self.Current.Achild.Add(tmp);
  tmp.name:=key;
  result:=pint64(tmp.ptr);
end;


function TATree.CurrentInto(varname:widestring):boolean;
var tmp:TAListUnit;
    tmp_name:utf8string;
begin
  result:=false;
  if Current.Achild.count=0 then exit;
  tmp:=Current.Achild.last{first};
  while tmp<>nil do
    begin
      tmp_name:=(tmp.obj as TATreeUnit).name;
      if tmp_name=varname then
        begin
          Current:=(tmp.obj as TATreeUnit);
          result:=true;
          exit;
        end;
      tmp:=tmp.prev{next};
    end;
end;

procedure TATree.CurrentInto(varname:widestring);
begin
  if not CurrentInto(varname) then begin MessageBox(0,'Cannot CurrentInto','Error',MB_OK);halt end;;
end;

function TATree.ChildExists(varname:widestring):boolean;
begin
  if CurrentInto(varname) then
    begin
      result:=true;
      CurrentOut;
    end
  else
    result:=false;
end;

procedure TATree.CurrentInto(ATreeUnit:TATreeUnit);
var tmp:TAListUnit;
begin
  Current:=ATreeUnit;
end;
procedure TATree.CurrentOut;
begin
  if Current=root then begin Self.IO_message(Auf.Script,'Cannot CurrentOut from root');halt end;
  Current:=Current.Aparent;
end;
procedure TATree.PrintJSON(filename:string='tree.json');
begin
  assignfile(JSON_file,filename);
  rewrite(JSON_file);
  write(JSON_file,'{');

  //((root.Achild.first.obj as TATreeUnit).Achild.last.obj as TATreeUnit).printJSON;
  //(root.Achild.first.obj as TATreeUnit).printJSON;
  root.PrintJSON;

  writeln(JSON_file);
  write(JSON_file,'}');
  closefile(Json_file);

end;




procedure de_cmd_writeln(Sender:TObject;str:string);
begin
  writeln(str);
end;
procedure de_gui_writeln(Sender:TObject;str:string);
begin
  ShowMessage(str);
end;

function level_space(level:integer):string;
var i:integer;
begin
  result:='';
  for i:=0 to level do result:=result+' ';
end;

function NBT_Typist(inp:NBT):string;
begin
  case inp of
    NBT_End:result:='End';
    NBT_Byte:result:='Byte';
    NBT_Short:result:='Short';
    NBT_Int:result:='Int';
    NBT_Long:result:='Long';
    NBT_Float:result:='Float';
    NBT_Double:result:='Double';
    NBT_ByteArray:result:='ByteArray';
    NBT_String:result:='String';
    NBT_List:result:='List';
    NBT_Compound:result:='Compound';
    NBT_IntArray:result:='IntArray';
    NBT_LongArray:result:='LongArray';
  end;
end;
function NBT_FullTypist(inp:NBT):string;
begin
  case inp of
    NBT_End:result:='Tag_End';
    NBT_Byte:result:='Tag_Byte';
    NBT_Short:result:='Tag_Short';
    NBT_Int:result:='Tag_Int';
    NBT_Long:result:='Tag_Long';
    NBT_Float:result:='Tag_Float';
    NBT_Double:result:='Tag_Double';
    NBT_ByteArray:result:='Tag_Byte_Array';
    NBT_String:result:='Tag_String';
    NBT_List:result:='Tag_List';
    NBT_Compound:result:='Tag_Compound';
    NBT_IntArray:result:='Tag_Int_Array';
    NBT_LongArray:result:='Tag_Long_Array';
  end;
end;

initialization
  //ATree:=TATree.Create;
  //ATree.IO_message:=@de_cmd_writeln;
  //ATree.JsonFileMode:=jfmExchange;


end.

