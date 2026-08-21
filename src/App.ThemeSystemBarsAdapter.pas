unit App.ThemeSystemBarsAdapter;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  FMX.Forms,
  App.ColorScheme,
  App.ThemeInterfaces,
  App.SystemBars;

type
  TSystemBarsService = class(TInterfacedObject, ISystemBarsService)
  public
    procedure ApplySystemBars(const AScheme: TColorScheme; const AIsDark: Boolean);
  end;

implementation

procedure TSystemBarsService.ApplySystemBars(const AScheme: TColorScheme; const AIsDark: Boolean);
var
  TargetForm: TCommonCustomForm;
begin
{$IFDEF ANDROID}
  TargetForm := Screen.ActiveForm;
  if TargetForm = nil then
    TargetForm := Application.MainForm;

  if TargetForm <> nil then
  begin
    TargetForm.SystemBars.StatusBarBackgroundColor := AScheme.Surface;
    TargetForm.SystemBars.NavigationBarBackgroundColor := AScheme.Surface;
  end;
{$ENDIF}
end;

end.
