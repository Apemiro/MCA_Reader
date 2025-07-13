program MCA_Reader;

{$mode objfpc}{$H+}
//{$APPTYPE CONSOLE}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, main, form_mapviewer, entities_definition, blocks_definition, mca_tile,
  color_rule, mca_base, selection_rule, Apiglio_Tree, Apiglio_Useful,
  auf_ram_var, aufscript_frame, kernel, auf_type_array, auf_type_base,
  apiglio_geo, Apiglio_ShapeFile, mc_world;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFormViewer, FormViewer);
  Application.Run;
end.

