unit App.SystemThemeDetector;

interface

uses
  System.SysUtils,
  FMX.Platform,
  App.ThemeInterfaces
  {$IFDEF ANDROID}
  , Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers
  {$ENDIF};

type
  TSystemThemeDetector = class(TInterfacedObject, ISystemThemeDetector)
  public
    function IsSystemDark: Boolean;
  end;

implementation

{ TSystemThemeDetector }

function TSystemThemeDetector.IsSystemDark: Boolean;
var
  Svc: IFMXSystemAppearanceService;
  {$IFDEF ANDROID}
  UIOptions: Integer;
  {$ENDIF}
begin
  Result := False;

  if (TPlatformServices.Current <> nil) and
     TPlatformServices.Current.SupportsPlatformService(IFMXSystemAppearanceService, Svc) then
  begin
    Result := (Svc.ThemeKind = TSystemThemeKind.Dark);
    Exit;
  end;

  {$IFDEF ANDROID}
  try
    if (TAndroidHelper.Context <> nil) and
       (TAndroidHelper.Context.getResources <> nil) and
       (TAndroidHelper.Context.getResources.getConfiguration <> nil) then
    begin
      UIOptions := TAndroidHelper.Context.getResources.getConfiguration.uiMode;
      Result := (UIOptions and TJConfiguration.JavaClass.UI_MODE_NIGHT_MASK) =
                TJConfiguration.JavaClass.UI_MODE_NIGHT_YES;
    end;
  except
    Result := False;
  end;
  {$ENDIF}
end;

end.
