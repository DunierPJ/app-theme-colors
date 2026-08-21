unit App.ThemeManager;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Messaging,
  App.ColorScheme,
  App.ThemeMessage,
  App.ThemeInterfaces,
  App.SystemThemeDetector,
  App.SystemBarsService;

type
  TThemeMode = App.ThemeInterfaces.TThemeMode;

  TThemeManagerImpl = class(TInterfacedObject, IThemeManager)
  private
    FMode: TThemeMode;
    FCustomLightScheme: TColorScheme;
    FCustomDarkScheme: TColorScheme;
    FHasCustomLight: Boolean;
    FHasCustomDark: Boolean;
    FSystemThemeDetector: ISystemThemeDetector;
    FSystemBarsService: ISystemBarsService;
    procedure AppearanceChanged(const Sender: TObject; const M: TMessage);
    function GetMode: TThemeMode;
    procedure SetMode(const Value: TThemeMode);
  public
    constructor Create(const ASystemThemeDetector: ISystemThemeDetector = nil;
      const ASystemBarsService: ISystemBarsService = nil);
    destructor Destroy; override;
    function IsDark: Boolean;
    function Scheme: TColorScheme;
    procedure SetCustomSchemes(const ALight, ADark: TColorScheme);
    procedure LoadSchemesFromJSON(const ALightJson, ADarkJson: string);
    procedure ApplySystemBars;
    property Mode: TThemeMode read GetMode write SetMode;
  end;

  TThemeManager = class
  private
    class var FInstance: IThemeManager;
    class function GetMode: TThemeMode; static;
    class procedure SetMode(const Value: TThemeMode); static;
  public
    class constructor Create;
    class destructor Destroy;
    class property Mode: TThemeMode read GetMode write SetMode;
    class function IsDark: Boolean; static;
    class function Scheme: TColorScheme; static;
    class procedure SetCustomSchemes(const ALight, ADark: TColorScheme); static;
    class procedure LoadSchemesFromJSON(const ALightJson, ADarkJson: string); static;
    class procedure ApplySystemBars; static;
    class property Instance: IThemeManager read FInstance;
  end;

implementation

{ TThemeManagerImpl }

constructor TThemeManagerImpl.Create(const ASystemThemeDetector: ISystemThemeDetector;
  const ASystemBarsService: ISystemBarsService);
begin
  inherited Create;
  FMode := tmSystem;
  FHasCustomLight := False;
  FHasCustomDark := False;

  if ASystemThemeDetector <> nil then
    FSystemThemeDetector := ASystemThemeDetector
  else
    FSystemThemeDetector := TSystemThemeDetector.Create;

  if ASystemBarsService <> nil then
    FSystemBarsService := ASystemBarsService
  else
    FSystemBarsService := TSystemBarsService.Create;

  if TMessageManager.DefaultManager <> nil then
    TMessageManager.DefaultManager.SubscribeToMessage(TSystemAppearanceChangedMessage, AppearanceChanged);
end;

destructor TThemeManagerImpl.Destroy;
begin
  if TMessageManager.DefaultManager <> nil then
    TMessageManager.DefaultManager.Unsubscribe(TSystemAppearanceChangedMessage, AppearanceChanged);
  FSystemThemeDetector := nil;
  FSystemBarsService := nil;
  inherited Destroy;
end;

function TThemeManagerImpl.GetMode: TThemeMode;
begin
  Result := FMode;
end;

procedure TThemeManagerImpl.SetMode(const Value: TThemeMode);
begin
  if FMode <> Value then
  begin
    FMode := Value;
    ApplySystemBars;
    if TMessageManager.DefaultManager <> nil then
      TMessageManager.DefaultManager.SendMessage(nil, TThemeChangedMessage.Create);
  end;
end;

function TThemeManagerImpl.IsDark: Boolean;
begin
  case FMode of
    tmDark: Result := True;
    tmLight: Result := False;
  else
    if FSystemThemeDetector <> nil then
      Result := FSystemThemeDetector.IsSystemDark
    else
      Result := False;
  end;
end;

function TThemeManagerImpl.Scheme: TColorScheme;
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

procedure TThemeManagerImpl.SetCustomSchemes(const ALight, ADark: TColorScheme);
begin
  FCustomLightScheme := ALight;
  FCustomDarkScheme := ADark;
  FHasCustomLight := True;
  FHasCustomDark := True;
  ApplySystemBars;
  if TMessageManager.DefaultManager <> nil then
    TMessageManager.DefaultManager.SendMessage(nil, TThemeChangedMessage.Create);
end;

procedure TThemeManagerImpl.LoadSchemesFromJSON(const ALightJson, ADarkJson: string);
begin
  SetCustomSchemes(
    TColorScheme.FromJSON(ALightJson, LightScheme),
    TColorScheme.FromJSON(ADarkJson, DarkScheme)
  );
end;

procedure TThemeManagerImpl.ApplySystemBars;
begin
  if FSystemBarsService <> nil then
    FSystemBarsService.ApplySystemBars(Scheme, IsDark);
end;

procedure TThemeManagerImpl.AppearanceChanged(const Sender: TObject; const M: TMessage);
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

{ TThemeManager }

class constructor TThemeManager.Create;
begin
  FInstance := TThemeManagerImpl.Create;
end;

class destructor TThemeManager.Destroy;
begin
  FInstance := nil;
end;

class function TThemeManager.GetMode: TThemeMode;
begin
  Result := FInstance.Mode;
end;

class procedure TThemeManager.SetMode(const Value: TThemeMode);
begin
  FInstance.Mode := Value;
end;

class function TThemeManager.IsDark: Boolean;
begin
  Result := FInstance.IsDark;
end;

class function TThemeManager.Scheme: TColorScheme;
begin
  Result := FInstance.Scheme;
end;

class procedure TThemeManager.SetCustomSchemes(const ALight, ADark: TColorScheme);
begin
  FInstance.SetCustomSchemes(ALight, ADark);
end;

class procedure TThemeManager.LoadSchemesFromJSON(const ALightJson, ADarkJson: string);
begin
  FInstance.LoadSchemesFromJSON(ALightJson, ADarkJson);
end;

class procedure TThemeManager.ApplySystemBars;
begin
  FInstance.ApplySystemBars;
end;

end.
