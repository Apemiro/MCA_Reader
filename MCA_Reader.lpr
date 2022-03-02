program MCA_Reader;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Apiglio_Useful, Apiglio_Tree, main, form_mapviewer,
  entities_definition, blocks_definition, mca_tile, color_rule, mca_base,
  selection_rule
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFormViewer, FormViewer);
  Application.Run;
end.

