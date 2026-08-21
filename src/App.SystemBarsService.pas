unit App.SystemBarsService;

interface

{$SCOPEDENUMS ON}
{$IFDEF ANDROID}

uses
  { Delphi }
  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  FMX.Forms,
  FMX.Platform,
  { App.SystemBars }
  App.SystemBars,
  { Subcomponents }
  App.SystemBars.Android.Types,
  App.SystemBars.Android.Interfaces,
  App.SystemBars.Android.WindowFix,
  App.SystemBars.Android.InsetsCalculator,
  App.SystemBars.Android.ColorController,
  App.SystemBars.Android.VisibilityController,
  App.SystemBars.Android.EventListener;

type
  { Backwards compatibility type aliases }
  TAndroid9 = App.SystemBars.Android.Types.TAndroid9;
  TAndroid10 = App.SystemBars.Android.Types.TAndroid10;
  TAndroid11 = App.SystemBars.Android.Types.TAndroid11;
{$IF CompilerVersion < 34.0}
  TAndroidBeforeMarshmallow = App.SystemBars.Android.Types.TAndroidBeforeMarshmallow;
{$IFEND}

  { ISystemBarsServiceAndroid }

  ISystemBarsServiceAndroid = interface(TScreenSystemBars.IFMXWindowSystemBarsService)
    ['{77586947-BF49-4938-9A34-51588E8BD915}']
    procedure CheckInsetsChanges(const AForm: TCommonCustomForm);
    function HasGestureNavigationBar(const AForm: TCommonCustomForm): Boolean;
    procedure TryFixInvisibleMode;
  end;

  { TSystemBarsServiceAndroid }

  TSystemBarsServiceAndroid = class(TInterfacedObject, ISystemBarsServiceAndroid, TScreenSystemBars.IFMXWindowSystemBarsService,
    IFMXWindowSystemStatusBarService, IFMXFullScreenWindowService)
  strict private
    FWindowServiceFix: IWindowServiceFix;
    FInsetsCalculator: ISystemBarsInsetsCalculator;
    FVisibilityController: ISystemBarsVisibilityController;
    FColorController: ISystemBarsColorController;
    FEventListener: ISystemBarsEventListener;
    FDefaultFullScreenService: IFMXFullScreenWindowService;
    FDefaultStatusBarService: IFMXWindowSystemStatusBarService;
    FRegisteredBarsService: Boolean;
    FRegisteredStatusBarService: Boolean;
  public
    constructor Create(
      const AWindowServiceFix: IWindowServiceFix = nil;
      const AInsetsCalculator: ISystemBarsInsetsCalculator = nil;
      const AVisibilityController: ISystemBarsVisibilityController = nil;
      const AColorController: ISystemBarsColorController = nil;
      const AEventListener: ISystemBarsEventListener = nil
    );
    destructor Destroy; override;

    { ISystemBarsServiceAndroid }
    procedure CheckInsetsChanges(const AForm: TCommonCustomForm);
    function HasGestureNavigationBar(const AForm: TCommonCustomForm): Boolean;
    procedure TryFixInvisibleMode;

    { IFMXWindowSystemBarsService }
    function GetInsets(const AForm: TCommonCustomForm): TRectF;
    function GetTappableInsets(const AForm: TCommonCustomForm): TRectF;
    procedure SetNavigationBarBackgroundColor(const AForm: TCommonCustomForm; const AColor: TAlphaColor);

    { IFMXWindowSystemStatusBarService / IFMXWindowSystemBarsService }
    procedure IFMXWindowSystemStatusBarService.SetBackgroundColor = SetStatusBarBackgroundColor;
    procedure SetStatusBarBackgroundColor(const AForm: TCommonCustomForm; const AColor: TAlphaColor);
    procedure SetVisibility(const AForm: TCommonCustomForm; const AMode: TScreenSystemBars.TVisibilityMode);

    { IFMXFullScreenWindowService }
    function GetFullScreen(const AForm: TCommonCustomForm): Boolean;
    procedure SetFullScreen(const AForm: TCommonCustomForm; const AValue: Boolean);
    procedure SetShowFullScreenIcon(const AForm: TCommonCustomForm; const AValue: Boolean);

    { Properties for injected components }
    property WindowServiceFix: IWindowServiceFix read FWindowServiceFix;
    property InsetsCalculator: ISystemBarsInsetsCalculator read FInsetsCalculator;
    property VisibilityController: ISystemBarsVisibilityController read FVisibilityController;
    property ColorController: ISystemBarsColorController read FColorController;
    property EventListener: ISystemBarsEventListener read FEventListener;
  end;

{$ELSE}
implementation
{$ENDIF}

{$IFDEF ANDROID}
implementation

var
  FSystemBarsServiceAndroid: ISystemBarsServiceAndroid;

{ TSystemBarsServiceAndroid }

constructor TSystemBarsServiceAndroid.Create(
  const AWindowServiceFix: IWindowServiceFix;
  const AInsetsCalculator: ISystemBarsInsetsCalculator;
  const AVisibilityController: ISystemBarsVisibilityController;
  const AColorController: ISystemBarsColorController;
  const AEventListener: ISystemBarsEventListener);
begin
  inherited Create;

  // Initialize or store Window Fix
  if Assigned(AWindowServiceFix) then
    FWindowServiceFix := AWindowServiceFix
  else
    FWindowServiceFix := TWindowServiceFix.Create;

  // Initialize or store Insets Calculator
  if Assigned(AInsetsCalculator) then
    FInsetsCalculator := AInsetsCalculator
  else
    FInsetsCalculator := TSystemBarsInsetsCalculator.Create;

  // Initialize or store Color Controller
  if Assigned(AColorController) then
    FColorController := AColorController
  else
    FColorController := TSystemBarsColorController.Create(FInsetsCalculator);

  // Initialize or store Visibility Controller
  if Assigned(AVisibilityController) then
    FVisibilityController := AVisibilityController
  else
    FVisibilityController := TSystemBarsVisibilityController.Create(FColorController, FInsetsCalculator);

  // Initialize or store Event Listener
  if Assigned(AEventListener) then
    FEventListener := AEventListener
  else
    FEventListener := TSystemBarsEventListener.Create(FInsetsCalculator, FVisibilityController);

  { IFMXWindowSystemBarsService }
  if TPlatformServices.Current.SupportsPlatformService(TScreenSystemBars.IFMXWindowSystemBarsService) then
    TPlatformServices.Current.RemovePlatformService(TScreenSystemBars.IFMXWindowSystemBarsService);
  TPlatformServices.Current.AddPlatformService(TScreenSystemBars.IFMXWindowSystemBarsService, Self);
  FRegisteredBarsService := True;

  { IFMXWindowSystemStatusBarService }
  if TPlatformServices.Current.SupportsPlatformService(IFMXWindowSystemStatusBarService, FDefaultStatusBarService) then
    TPlatformServices.Current.RemovePlatformService(IFMXWindowSystemStatusBarService);
  TPlatformServices.Current.AddPlatformService(IFMXWindowSystemStatusBarService, Self);
  FRegisteredStatusBarService := True;

  { IFMXFullScreenWindowService }
  if TPlatformServices.Current.SupportsPlatformService(IFMXFullScreenWindowService, FDefaultFullScreenService) then
    TPlatformServices.Current.RemovePlatformService(IFMXFullScreenWindowService);
  TPlatformServices.Current.AddPlatformService(IFMXFullScreenWindowService, Self);

  FEventListener.StartListening;
end;

destructor TSystemBarsServiceAndroid.Destroy;
begin
  if Assigned(FEventListener) then
    FEventListener.StopListening;

  if TPlatformServices.Current <> nil then
  begin
    { IFMXFullScreenWindowService }
    TPlatformServices.Current.RemovePlatformService(IFMXFullScreenWindowService);
    if Assigned(FDefaultFullScreenService) then
      TPlatformServices.Current.AddPlatformService(IFMXFullScreenWindowService, FDefaultFullScreenService);
    { IFMXWindowSystemBarsService }
    if FRegisteredBarsService then
      TPlatformServices.Current.RemovePlatformService(TScreenSystemBars.IFMXWindowSystemBarsService);
    { IFMXWindowSystemStatusBarService }
    if FRegisteredStatusBarService then
    begin
      TPlatformServices.Current.RemovePlatformService(IFMXWindowSystemStatusBarService);
      if Assigned(FDefaultStatusBarService) then
        TPlatformServices.Current.AddPlatformService(IFMXWindowSystemStatusBarService, FDefaultStatusBarService);
    end;
  end;

  FEventListener := nil;
  FVisibilityController := nil;
  FColorController := nil;
  FInsetsCalculator := nil;
  FWindowServiceFix := nil;

  inherited;
end;

procedure TSystemBarsServiceAndroid.CheckInsetsChanges(const AForm: TCommonCustomForm);
begin
  if Assigned(FEventListener) then
    FEventListener.CheckInsetsChanges(AForm);
end;

function TSystemBarsServiceAndroid.GetFullScreen(const AForm: TCommonCustomForm): Boolean;
begin
  if Assigned(FVisibilityController) then
    Result := FVisibilityController.GetFullScreen(AForm)
  else
    Result := False;
end;

function TSystemBarsServiceAndroid.GetInsets(const AForm: TCommonCustomForm): TRectF;
begin
  if Assigned(FInsetsCalculator) then
    Result := FInsetsCalculator.GetInsets(AForm)
  else
    Result := TRectF.Empty;
end;

function TSystemBarsServiceAndroid.GetTappableInsets(const AForm: TCommonCustomForm): TRectF;
begin
  if Assigned(FInsetsCalculator) then
    Result := FInsetsCalculator.GetTappableInsets(AForm)
  else
    Result := TRectF.Empty;
end;

function TSystemBarsServiceAndroid.HasGestureNavigationBar(const AForm: TCommonCustomForm): Boolean;
begin
  if Assigned(FInsetsCalculator) then
    Result := FInsetsCalculator.HasGestureNavigationBar(AForm)
  else
    Result := False;
end;

procedure TSystemBarsServiceAndroid.SetFullScreen(const AForm: TCommonCustomForm; const AValue: Boolean);
begin
  if Assigned(FVisibilityController) then
    FVisibilityController.SetFullScreen(AForm, AValue);
end;

procedure TSystemBarsServiceAndroid.SetNavigationBarBackgroundColor(const AForm: TCommonCustomForm; const AColor: TAlphaColor);
begin
  if Assigned(FColorController) then
    FColorController.SetNavigationBarBackgroundColor(AForm, AColor);
end;

procedure TSystemBarsServiceAndroid.SetShowFullScreenIcon(const AForm: TCommonCustomForm; const AValue: Boolean);
begin
  if Assigned(FVisibilityController) then
    FVisibilityController.SetShowFullScreenIcon(AForm, AValue);
end;

procedure TSystemBarsServiceAndroid.SetStatusBarBackgroundColor(const AForm: TCommonCustomForm; const AColor: TAlphaColor);
begin
  if Assigned(FColorController) then
    FColorController.SetStatusBarBackgroundColor(AForm, AColor);
end;

procedure TSystemBarsServiceAndroid.SetVisibility(const AForm: TCommonCustomForm; const AMode: TScreenSystemBars.TVisibilityMode);
begin
  if Assigned(FEventListener) then
    FEventListener.ChangeChecksEnabled := False;
  try
    if Assigned(FVisibilityController) then
      FVisibilityController.SetVisibility(AForm, AMode);
  finally
    if Assigned(FEventListener) then
      FEventListener.ChangeChecksEnabled := True;
  end;
  if Assigned(FEventListener) then
    FEventListener.CheckInsetsChanges(AForm);
end;

procedure TSystemBarsServiceAndroid.TryFixInvisibleMode;
begin
  if Assigned(FVisibilityController) then
    FVisibilityController.TryFixInvisibleMode;
end;

initialization
  FSystemBarsServiceAndroid := TSystemBarsServiceAndroid.Create;

{$ENDIF}

end.
