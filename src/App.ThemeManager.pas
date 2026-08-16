unit App.ThemeManager;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes, 
  System.Messaging, 
  FMX.Platform, 
  App.ColorScheme, 
  App.ThemeMessage
  {$IFDEF ANDROID}
  , Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Os,
  Androidapi.Helpers
  {$ENDIF};

type
  TThemeMode = (tmSystem, tmLight, tmDark);

  TThemeManager = class
  private
    class var FMode: TThemeMode;
    class var FCustomLightScheme: TColorScheme;
    class var FCustomDarkScheme: TColorScheme;
    class var FHasCustomLight: Boolean;
    class var FHasCustomDark: Boolean;
    class function SystemIsDark: Boolean; static;
    class procedure AppearanceChanged(const Sender: TObject; const M: TMessage); static;
    class procedure SetMode(const Value: TThemeMode); static;
  public
    class constructor Create;
    class destructor Destroy;
    class property Mode: TThemeMode read FMode write SetMode;
    class function IsDark: Boolean; static;
    class function Scheme: TColorScheme; static;
    class procedure SetCustomSchemes(const ALight, ADark: TColorScheme); static;
    class procedure LoadSchemesFromJSON(const ALightJson, ADarkJson: string); static;
    class procedure ApplySystemBars; static;
  end;

implementation

class constructor TThemeManager.Create;
begin
  FMode := tmSystem;
  FHasCustomLight := False;
  FHasCustomDark := False;
  if TMessageManager.DefaultManager <> nil then
    TMessageManager.DefaultManager.SubscribeToMessage(TSystemAppearanceChangedMessage, AppearanceChanged);
end;

class destructor TThemeManager.Destroy;
begin
  if TMessageManager.DefaultManager <> nil then
    TMessageManager.DefaultManager.Unsubscribe(TSystemAppearanceChangedMessage, AppearanceChanged);
end;

class procedure TThemeManager.SetMode(const Value: TThemeMode);
begin
  if FMode <> Value then
  begin
    FMode := Value;
    ApplySystemBars;
    if TMessageManager.DefaultManager <> nil then
      TMessageManager.DefaultManager.SendMessage(nil, TThemeChangedMessage.Create);
  end;
end;

class procedure TThemeManager.SetCustomSchemes(const ALight, ADark: TColorScheme);
begin
  FCustomLightScheme := ALight;
  FCustomDarkScheme := ADark;
  FHasCustomLight := True;
  FHasCustomDark := True;
  ApplySystemBars;
  if TMessageManager.DefaultManager <> nil then
    TMessageManager.DefaultManager.SendMessage(nil, TThemeChangedMessage.Create);
end;

class procedure TThemeManager.LoadSchemesFromJSON(const ALightJson, ADarkJson: string);
begin
  SetCustomSchemes(
    TColorScheme.FromJSON(ALightJson, LightScheme),
    TColorScheme.FromJSON(ADarkJson, DarkScheme)
  );
end;

class procedure TThemeManager.ApplySystemBars;
{$IFDEF ANDROID}
var
  Window: JWindow;
  DecorView: JView;
  InsetsController: JWindowInsetsController;
  ViewFlags: Integer;
  Appearance, Mask: Integer;
  CurScheme: TColorScheme;
  IsDarkMode: Boolean;
{$ENDIF}
begin
{$IFDEF ANDROID}
  if (TAndroidHelper.Activity = nil) or (TAndroidHelper.Activity.getWindow = nil) then
    Exit;
  CurScheme := Scheme;
  IsDarkMode := IsDark;
  TThread.Queue(nil,
    procedure
    begin
      try
        Window := TAndroidHelper.Activity.getWindow;
        if Window = nil then Exit;
        DecorView := Window.getDecorView;
        if DecorView = nil then Exit;

        // ---- SDK_INT >= 21 (Android 5.0) — cor de fundo das barras ----
        if TJBuild_VERSION.JavaClass.SDK_INT >= 21 then
        begin
          Window.clearFlags(TJWindowManager_LayoutParams.JavaClass.FLAG_TRANSLUCENT_STATUS or
                            TJWindowManager_LayoutParams.JavaClass.FLAG_TRANSLUCENT_NAVIGATION);
          Window.addFlags(TJWindowManager_LayoutParams.JavaClass.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
          Window.setStatusBarColor(CurScheme.Surface);
          Window.setNavigationBarColor(CurScheme.Surface);
        end;

        // ---- SDK_INT >= 23 (Android 6.0) — ícones da status bar ----
        if TJBuild_VERSION.JavaClass.SDK_INT >= 23 then
        begin
          ViewFlags := DecorView.getSystemUiVisibility;
          if not IsDarkMode then
            ViewFlags := ViewFlags or TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
          else
            ViewFlags := ViewFlags and not TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;

          // ---- SDK_INT >= 26 (Android 8.0) — ícones da nav bar ----
          if TJBuild_VERSION.JavaClass.SDK_INT >= 26 then
          begin
            if not IsDarkMode then
              ViewFlags := ViewFlags or TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
            else
              ViewFlags := ViewFlags and not TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
          end;

          // ---- SDK_INT >= 30 (Android 11) — API nova via WindowInsetsController ----
          if TJBuild_VERSION.JavaClass.SDK_INT >= 30 then
          begin
            InsetsController := Window.getInsetsController;
            if InsetsController <> nil then
            begin
              Mask := TJWindowInsetsController.JavaClass.APPEARANCE_LIGHT_STATUS_BARS or
                      TJWindowInsetsController.JavaClass.APPEARANCE_LIGHT_NAVIGATION_BARS;

              Appearance := 0;
              if not IsDarkMode then
                Appearance := Mask;

              InsetsController.setSystemBarsAppearance(Appearance, Mask);
            end;
          end
          else
            DecorView.setSystemUiVisibility(ViewFlags);
        end;
      except
        // Ignora erros de ciclo de vida da Activity
      end;
    end);
{$ENDIF}
end;

class function TThemeManager.SystemIsDark: Boolean;
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

class function TThemeManager.IsDark: Boolean;
begin
  case FMode of
    tmDark: Result := True;
    tmLight: Result := False;
  else
    Result := SystemIsDark;
  end;
end;

class function TThemeManager.Scheme: TColorScheme;
begin
  if IsDark then
  begin
    if FHasCustomDark then
      Result := FCustomDarkScheme
    else
      Result := DarkScheme;
  end
  else
  begin
    if FHasCustomLight then
      Result := FCustomLightScheme
    else
      Result := LightScheme;
  end;
end;

class procedure TThemeManager.AppearanceChanged(const Sender: TObject; const M: TMessage);
begin
  if FMode = tmSystem then
  begin
    ApplySystemBars;
    TThread.Queue(nil,
      procedure
      begin
        if TMessageManager.DefaultManager <> nil then
          TMessageManager.DefaultManager.SendMessage(nil, TThemeChangedMessage.Create);
      end);
  end;
end;

end.

