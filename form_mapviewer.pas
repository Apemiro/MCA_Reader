unit form_mapviewer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, main, Apiglio_Useful;

type

  TAufImage = class(TImage)
    FAuf:TAuf;
  public
    constructor Create(AOwner:TComponent);
    destructor Destroy;override;
  end;


  { TFormViewer }

  TFormViewer = class(TForm)
    ScrollBox_Display: TScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { private declarations }
  public

  end;

var
  FormViewer: TFormViewer;

implementation

{$R *.lfm}

{ TAufImage }

constructor TAufImage.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  FAuf:=TAuf.Create(AOwner);
  FAuf.Script.InternalFuncDefine;
  FormMain.AufInit(FAuf.Script);
end;

destructor TAufImage.Destroy;
begin
  FAuf.Free;
  inherited Destroy;
end;

{ TFormViewer }

procedure TFormViewer.FormResize(Sender: TObject);
begin


end;

procedure TFormViewer.FormCreate(Sender: TObject);
begin

end;

end.

