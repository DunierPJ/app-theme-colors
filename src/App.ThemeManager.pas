unit App.ThemeManager;

interface

uses
  System.UITypes, 
  System.Messaging, 
  FMX.Platform, 
  App.ColorScheme, 
  App.ThemeMessage;

type
  TThemeMode = (tmSystem, tmLight, tmDark);

  TThemeManager = class
  private
    class var FMode: TThemeMode;
    class function SystemIsDark: Boolean; static;
    class procedure AppearanceChanged(const Sender: TObject; const M: TMessage); static;
    class procedure TThemeManager.SetMode(const Value: TThemeMode); static;
  public
    class constructor Create;
    class destructor Destroy;
    class property Mode: TThemeMode read FMode write SetMode;
    class function IsDark: Boolean; static;
    class function Scheme: TColorScheme; static;
  end;

implementation

class constructor TThemeManager.Create;
begin
  FMode := tmSystem;
  TMessageManager.DefaultManager.SubscribeToMessage(TMessageSystemAppearanceChanged, AppearanceChanged);
end;

class destructor TThemeManager.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TMessageSystemAppearanceChanged, AppearanceChanged);
end;

// e no setter de Mode, se você tornar a property com write de método em vez de campo direto:
class procedure TThemeManager.SetMode(const Value: TThemeMode);
begin
  FMode := Value;
  TMessageManager.DefaultManager.SendMessage(nil, TThemeChangedMessage.Create);
end;

class function TThemeManager.SystemIsDark: Boolean;
var
  Svc: IFMXSystemAppearanceService;
begin
  Result := False;
  if TPlatformServices.Current.SupportsPlatformService(IFMXSystemAppearanceService, Svc) then
    Result := Svc.ThemeKind = TSystemThemeKind.Dark;
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
    Result := DarkScheme
  else
    Result := LightScheme;
end;

class procedure TThemeManager.AppearanceChanged(const Sender: TObject; const M: TMessage);
begin
  // dispare aqui seu próprio evento/mensagem pra repintar a UI, ex:
  TMessageManager.DefaultManager.SendMessage(nil, TThemeChangedMessage.Create);
end;

end.