unit App.SystemThemeDetector;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Messaging,
  FMX.Platform,
  App.ThemeInterfaces
  {$IFDEF ANDROID}
  , Androidapi.JNIBridge,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers,
  Androidapi.Jni
  {$ENDIF};

{$IFDEF ANDROID}
type
  JComponentCallbacksContextClass = interface(JContextClass)
    ['{4D8B6F21-3A5C-4E97-B1D4-8F2A6C9E3B04}']
  end;

  [JavaSignature('android/content/Context')]
  JComponentCallbacksContext = interface(JContext)
    ['{C1E4A7D2-9B3F-4680-A5C7-2E9D4B8F1A63}']
    procedure registerComponentCallbacks(callback: ILocalObject); cdecl;
    procedure unregisterComponentCallbacks(callback: ILocalObject); cdecl;
  end;

  TJComponentCallbacksContext = class(TJavaGenericImport<JComponentCallbacksContextClass, JComponentCallbacksContext>)
  end;

  JComponentCallbacksClass = interface(IJavaClass)
    ['{9E5C9A3D-2B41-4C0E-8B7A-1F6D2A9E5C31}']
  end;

  [JavaSignature('android/content/ComponentCallbacks')]
  JComponentCallbacks = interface(IJavaInstance)
    ['{7A2F1E4B-6C9D-4A82-9E3F-5B8C1D4A7E62}']
    procedure onConfigurationChanged(newConfig: JConfiguration); cdecl;
    procedure onLowMemory; cdecl;
  end;
{$ENDIF}

type
  TSystemThemeDetector = class(TInterfacedObject, ISystemThemeDetector)
  strict private
    FLastKnownDark: Boolean;
    FListening: Boolean;
    FOnChange: TNotifyEvent;
    {$IFDEF ANDROID}
    type

      TConfigChangeListener = class(TJavaLocal, JComponentCallbacks)
      strict private
        FOwner: TSystemThemeDetector;
      public
        constructor Create(const AOwner: TSystemThemeDetector);
        // JComponentCallbacks
        procedure onConfigurationChanged(newConfig: JConfiguration); cdecl;
        procedure onLowMemory; cdecl;
      end;
    var
      FConfigListener: TConfigChangeListener;
    {$ENDIF}
    procedure HandleConfigurationChanged;
    {$IFNDEF ANDROID}

    procedure ApplicationEventHandler(const Sender: TObject; const M: TMessage);
    var
      FAppEventSubscriptionId: Integer;
    {$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
    { ISystemThemeDetector }
    function IsSystemDark: Boolean;
    procedure StartListening;
    procedure StopListening;
    procedure SetOnChange(const AHandler: TNotifyEvent);
  end;

implementation

{$IFDEF ANDROID}
{ TSystemThemeDetector.TConfigChangeListener }

constructor TSystemThemeDetector.TConfigChangeListener.Create(const AOwner: TSystemThemeDetector);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TSystemThemeDetector.TConfigChangeListener.onConfigurationChanged(newConfig: JConfiguration);
begin
  // Chamado pelo Android só quando a configuração muda de verdade
  // (inclui uiMode/dark mode). Zero polling, zero bateria extra.
  if Assigned(FOwner) then
    FOwner.HandleConfigurationChanged;
end;

procedure TSystemThemeDetector.TConfigChangeListener.onLowMemory;
begin
  // Exigido pela interface ComponentCallbacks; não usado aqui.
end;
{$ENDIF}

{ TSystemThemeDetector }

constructor TSystemThemeDetector.Create;
begin
  inherited Create;
  FLastKnownDark := IsSystemDark;
  {$IFNDEF ANDROID}
  FAppEventSubscriptionId := -1;
  {$ENDIF}
end;

destructor TSystemThemeDetector.Destroy;
begin
  StopListening;
  FOnChange := nil;
  inherited Destroy;
end;

function TSystemThemeDetector.IsSystemDark: Boolean;
var
  Svc: IFMXSystemAppearanceService;
  {$IFDEF ANDROID}
  UIOptions: Integer;
  {$ENDIF}
begin
  Result := False;

  {$IFDEF ANDROID}
  try
    if (TAndroidHelper.Context <> nil) and
       (TAndroidHelper.Context.getResources <> nil) and
       (TAndroidHelper.Context.getResources.getConfiguration <> nil) then
    begin
      UIOptions := TAndroidHelper.Context.getResources.getConfiguration.uiMode;
      Result := (UIOptions and TJConfiguration.JavaClass.UI_MODE_NIGHT_MASK) =
                TJConfiguration.JavaClass.UI_MODE_NIGHT_YES;
      Exit;
    end;
  except
    Result := False;
  end;
  {$ENDIF}

  if (TPlatformServices.Current <> nil) and
     TPlatformServices.Current.SupportsPlatformService(IFMXSystemAppearanceService, Svc) then
  begin
    Result := (Svc.ThemeKind = TSystemThemeKind.Dark);
    Exit;
  end;
end;

procedure TSystemThemeDetector.SetOnChange(const AHandler: TNotifyEvent);
begin
  FOnChange := AHandler;
end;

procedure TSystemThemeDetector.HandleConfigurationChanged;
var
  LCurrentDark: Boolean;
begin
  LCurrentDark := IsSystemDark;
  if LCurrentDark <> FLastKnownDark then
  begin
    FLastKnownDark := LCurrentDark;
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TSystemThemeDetector.StartListening;
begin
  if FListening then
    Exit;

  FLastKnownDark := IsSystemDark;

  {$IFDEF ANDROID}
  if Assigned(TAndroidHelper.Context) then
  begin
    FConfigListener := TConfigChangeListener.Create(Self);
    TJComponentCallbacksContext
      .Wrap(TAndroidHelper.JObjectToID(TAndroidHelper.Context))
      .registerComponentCallbacks(FConfigListener);
  end;
  {$ELSE}

  if (TMessageManager.DefaultManager <> nil) and (FAppEventSubscriptionId = -1) then
    FAppEventSubscriptionId := TMessageManager.DefaultManager
      .SubscribeToMessage(TApplicationEventMessage, ApplicationEventHandler);
  {$ENDIF}

  FListening := True;
end;

procedure TSystemThemeDetector.StopListening;
begin
  if not FListening then
    Exit;

  {$IFDEF ANDROID}
  if Assigned(FConfigListener) then
  begin
    if Assigned(TAndroidHelper.Context) then
      TJComponentCallbacksContext
        .Wrap(TAndroidHelper.JObjectToID(TAndroidHelper.Context))
        .unregisterComponentCallbacks(FConfigListener);
    FreeAndNil(FConfigListener);
  end;
  {$ELSE}
  if (TMessageManager.DefaultManager <> nil) and (FAppEventSubscriptionId <> -1) then
  begin
    TMessageManager.DefaultManager
      .Unsubscribe(TApplicationEventMessage, ApplicationEventHandler);
    FAppEventSubscriptionId := -1;
  end;
  {$ENDIF}

  FListening := False;
end;

{$IFNDEF ANDROID}
procedure TSystemThemeDetector.ApplicationEventHandler(const Sender: TObject; const M: TMessage);
begin
  if (M is TApplicationEventMessage) and
     (TApplicationEventMessage(M).Value.Event = TApplicationEvent.BecameActive) then
    HandleConfigurationChanged;
end;
{$ENDIF}

end.
