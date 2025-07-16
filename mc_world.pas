unit mc_world;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, FileUtil,
    Apiglio_Tree, blocks_definition,
    mca_tile, mca_base, entities_definition, selection_rule;

const _sep_ = DirectorySeparator;

type
    TMC_World_Platform   = (wpJava, wpBedrock);
    TMC_World_Dimension  = (wdOverWorld=0, wdTheNether=-1, wdTheEnd=1);
    TMC_World_Projection = STRING;
    TMC_World_ExportOpt  = (weoEntities, weoTileEnts, weoBlockPlan, weoBiome, weoHeight);
    TMC_World_ExportOpts = set of TMC_World_ExportOpt;


    TMC_World = class
    private
        FFolderPath   : string;
        FExportPath   : string;
        FEntities     : TEntities;
        FTileEnts     : TEntities;
        FBlockPlan    : TMCA_Tile_List; //用于平面显示
        FBlockBiome   : TMCA_Tile_List; //用于平面显示
        FBlockHeight  : TMCA_Tile_List; //用于平面显示
        //defaultBlocks之后改到这里
    public
        property FolderPath : string read FFolderPath;
        property ExportPath : string read FExportPath write FExportPath;
    public
        WorldSetting   : record
            Platform       : TMC_World_Platform;
            Version        : string;
            SaveChk        : boolean;
            SaveJson       : boolean;
        end;
        DisplaySetting : record
            Dimension      : TMC_World_Dimension;
            ExportOpts     : TMC_World_ExportOpts;
            Projection     : TMC_World_Projection;
            ClipFloor      : Integer;
            PSelection     : TSelectionRule;
        end;
    protected
        procedure ReadRegion;
        procedure ReadEntities;
        procedure ReadPOI;
    public
        procedure ReadWorld;
        procedure SaveToPath;
    public
        constructor Create(Path:string);
        destructor Destroy;override;
    end;

implementation


procedure TMC_World.readRegion;
var mca_file_list:TStringList;
    mca_file_name:string;
    MCA_file_path:string;
    chunkId,xPos,zPos:integer;
    mca:TMCA_Stream;
    chk:TChunk_Stream;
    blk:TChunk_Block;
    tree:TATree;
begin
    case DisplaySetting.Dimension of
        wdOverWorld:
        begin
            MCA_file_path:='region';
            if not DirectoryExists(FFolderPath+_sep_+MCA_file_path) then MCA_file_path:='';
        end;
        wdTheNether:
        begin
            MCA_file_path:='DIM-1';
            if not DirectoryExists(FFolderPath+_sep_+MCA_file_path) then begin
                MCA_file_path:='DIM-1'+_sep_+'region';
                if not DirectoryExists(FFolderPath+_sep_+MCA_file_path) then MCA_file_path:='';
            end;
        end;
        wdTheEnd:
        begin
            MCA_file_path:='DIM1';
            if not DirectoryExists(FFolderPath+_sep_+MCA_file_path) then begin
                MCA_file_path:='DIM1'+_sep_+'region';
                if not DirectoryExists(FFolderPath+_sep_+MCA_file_path) then MCA_file_path:='';
            end;
        end;
        else raise Exception.Create('invalid DisplaySetting.Dimension');
    end;
    if MCA_file_path='' then raise Exception.Create('Cannot find region folder');


    mca_file_list:=TStringList.Create;
    mca:=TMCA_Stream.Create;
    chk:=TChunk_Stream.Create;
    blk:=TChunk_Block.Create;
    tree:=TATree.Create;
    try
        FindAllFiles(mca_file_list, FFolderPath+_sep_+MCA_file_path, '*.mca', false, faAnyFile);
        for mca_file_name in mca_file_list do begin
            mca.LoadFromFile(mca_file_name);
            for chunkId:=0 to 1023 do begin
                xPos:=512*mca.x+chunkId mod 32;
                zPos:=512*mca.z+chunkId div 32;
                if not mca.ChunkAvailable(chunkId) then continue;
                if not chk.LoadFromMCA(chunkId,mca) then continue;
                tree.Clear;
                chk.Decode(tree);
                if WorldSetting.SaveJson then
                    tree.PrintJSON(Format('%s%stree[%d,%d].json',[FExportPath, _sep_, xPos, zPos]));


                with DisplaySetting do begin
                    if (weoBiome in ExportOpts)
                      or (weoHeight in ExportOpts)
                      or (weoBlockPlan in ExportOpts)
                      or WorldSetting.SaveChk
                        then begin
                            blk.LoadFromTree(tree);
                            if WorldSetting.SaveChk then
                                blk.SaveByteToFile(Format('%s%sblocks[%d,%d].chk',[FExportPath, _sep_, xPos, zPos]));
                        end;
                    if weoBlockPlan in ExportOpts then
                        FBlockPlan.GetChunkPlan(blk, Projection, ClipFloor, Byte(smExclude), PSelection);
                    if weoHeight in ExportOpts then
                        FBlockHeight.GetChunkPlan(blk, 'height');
                    if weoBiome in ExportOpts then
                        FBlockBiome.GetChunkPlan(blk, 'biomes');
                    if weoTileEnts in ExportOpts then
                        FTileEnts.LoadFromTree(tree);
                    if weoEntities in ExportOpts then
                        FEntities.LoadFromTree(tree);
                end;

            end;
        end;
    finally
        mca_file_list.Free;
        mca.Free;
        chk.Free;
        blk.Free;
        tree.Free;
    end;
end;

procedure TMC_World.readEntities;
var mca_file_list:TStringList;
    mca_file_name:string;
    MCA_file_path:string;
    chunkId:integer;
    mca:TMCA_Stream;
    chk:TChunk_Stream;
    tree:TATree;
begin

    if not (weoEntities in DisplaySetting.ExportOpts) then exit;

    case DisplaySetting.Dimension of
        wdOverWorld:
        begin
            MCA_file_path:='entities';
            if not DirectoryExists(FFolderPath+_sep_+MCA_file_path) then MCA_file_path:='';
        end;
        wdTheNether:
        begin
            MCA_file_path:='DIM-1';
            if not DirectoryExists(FFolderPath+_sep_+MCA_file_path) then begin
                MCA_file_path:='DIM-1'+_sep_+'entities';
                if not DirectoryExists(FFolderPath+_sep_+MCA_file_path) then MCA_file_path:='';
            end;
        end;
        wdTheEnd:
        begin
            MCA_file_path:='DIM1';
            if not DirectoryExists(FFolderPath+_sep_+MCA_file_path) then begin
                MCA_file_path:='DIM1'+_sep_+'entities';
                if not DirectoryExists(FFolderPath+_sep_+MCA_file_path) then MCA_file_path:='';
            end;
        end;
        else raise Exception.Create('invalid DisplaySetting.Dimension');
    end;
    if MCA_file_path='' then raise Exception.Create('Cannot find region folder');


    mca_file_list:=TStringList.Create;
    mca:=TMCA_Stream.Create;
    chk:=TChunk_Stream.Create;
    tree:=TATree.Create;
    try
        FindAllFiles(mca_file_list, FFolderPath+_sep_+MCA_file_path, '*.mca', false, faAnyFile);
        for mca_file_name in mca_file_list do begin
            mca.LoadFromFile(mca_file_name);
            for chunkId:=0 to 1023 do begin
                if not mca.ChunkAvailable(chunkId) then continue;
                if not chk.LoadFromMCA(chunkId,mca) then continue;
                tree.Clear;
                chk.Decode(tree);
                FEntities.LoadFromTree(tree);
            end;
        end;
    finally
        mca_file_list.Free;
        mca.Free;
        chk.Free;
        tree.Free;
    end;
end;

procedure TMC_World.readPOI;
begin

end;


procedure TMC_World.ReadWorld;
begin
    ReadRegion;
    ReadEntities;
    ReadPOI;
end;

procedure TMC_World.SaveToPath;
var arcpy_automation:text;
begin
    if not ForceDirectories(FExportPath) then raise Exception.Create('无法创建路径：'+FExportPath);
    FBlockPlan.SaveAsTiff(FExportPath+_sep_+'blockplan');
    FBlockBiome.SaveAsTiff(FExportPath+_sep_+'biome');
    FBlockHeight.SaveAsTiff(FExportPath+_sep_+'blockheight');
    FEntities.SaveAsShp(FExportPath+_sep_+'entities');
    FTileEnts.SaveAsShp(FExportPath+_sep_+'tileents');

    AssignFile(arcpy_automation, FExportPath+_sep_+'arcpy_automation.py');
    Rewrite(arcpy_automation);
    WriteLn(arcpy_automation,'import arcpy');
    WriteLn(arcpy_automation,'arcpy.env.workspace = r"'+FFolderPath+_sep_+'MCA_Reader'+'"');
    WriteLn(arcpy_automation,'b1=arcpy.Raster("blockplan.tif/Band_1")');
    WriteLn(arcpy_automation,'b2=arcpy.Raster("blockplan.tif/Band_2")');
    WriteLn(arcpy_automation,'block = b1*256+b2');
    WriteLn(arcpy_automation,'block.save("blockplan_stat.tif")');
    WriteLn(arcpy_automation,'arcpy.management.AddField("blockplan_stat.tif","NAME","TEXT",field_length=50)');
    WriteLn(arcpy_automation,'blockmap={'+defaultBlocks.ExportToString(',')+'}');
    WriteLn(arcpy_automation,'biomemap={'+defaultBiomes.ExportToString(',')+'}');
    //WriteLn(arcpy_automation,'POImap='+defaultPOIs.ExportToString(','));
    WriteLn(arcpy_automation,'with arcpy.da.UpdateCursor("blockplan_stat.tif",["VALUE","NAME"]) as cursor:');
    WriteLn(arcpy_automation,'    for row in cursor:');
    WriteLn(arcpy_automation,'        name = blockmap.get(row[0])');
    WriteLn(arcpy_automation,'        row[1] = name if name!=None else ""');
    WriteLn(arcpy_automation,'        cursor.updateRow(row)');
    WriteLn(arcpy_automation,'');
    WriteLn(arcpy_automation,'bio3=arcpy.Raster("biome.tif/Band_3")');
    WriteLn(arcpy_automation,'biome=bio3 # 目前生物群系还没有超过255不需要多波段计算');
    WriteLn(arcpy_automation,'biome.save("biome_stat.tif")');
    WriteLn(arcpy_automation,'arcpy.management.AddField("biome_stat.tif","NAME","TEXT",field_length=50)');
    WriteLn(arcpy_automation,'with arcpy.da.UpdateCursor("biome_stat.tif",["VALUE","NAME"]) as cursor:');
    WriteLn(arcpy_automation,'    for row in cursor:');
    WriteLn(arcpy_automation,'        name = biomemap.get(row[0])');
    WriteLn(arcpy_automation,'        row[1] = name if name!=None else ""');
    WriteLn(arcpy_automation,'        cursor.updateRow(row)');
    WriteLn(arcpy_automation,'None # 避免复制到ArcGIS时的卡顿');


    CloseFile(arcpy_automation);

end;

constructor TMC_World.Create(Path:string);
begin
    if not DirectoryExists(Path) then exit;
    inherited Create;
    FFolderPath:=Path;
    FExportPath:=Path+_sep_+'MCA_Reader';
    ForceDirectories(FExportPath);
    with WorldSetting do begin
        Platform   := wpJava;
        SaveChk    := false;
        SaveJson   := false;
    end;
    with DisplaySetting do begin
        Dimension  := wdOverWorld;
        ExportOpts := [weoBlockPlan, weoBiome, weoHeight, weoEntities, weoTileEnts];
        Projection := 'below';
        ClipFloor  := 127;
        PSelection := TSelectionRule.Create;
    end;
    FEntities      := TEntities.Create;
    FTileEnts      := TEntities.Create;
    FBlockPlan     := TMCA_Tile_List.Create;
    FBlockBiome    := TMCA_Tile_List.Create;
    FBlockHeight   := TMCA_Tile_List.Create;

    FEntities.LoadEntities:=true;
    FEntities.LoadTileEnts:=false;
    FTileEnts.LoadEntities:=false;
    FTileEnts.LoadTileEnts:=true;

end;

destructor TMC_World.Destroy;
begin
    DisplaySetting.PSelection.Free;
    FEntities.Free;
    FTileEnts.Free;
    FBlockPlan.Free;
    FBlockBiome.Free;
    FBlockHeight.Free;
    inherited Destroy;
end;


end.

