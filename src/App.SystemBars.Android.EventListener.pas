unit App.SystemBars.Android.EventListener;

interface

{$SCOPEDENUMS ON}
{$IFDEF ANDROID}

uses
  { Delphi }
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Messaging,
  System.Classes,
  System.Math.Vectors,
  FMX.Types,
  FMX.Utils,
  FMX.Forms,
  FMX.Platform,
  FMX.Platform.Android,
  Androidapi.JNIBridge,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers,
  Androidapi.Jni,
  Androidapi.JNI.App,
  App.SystemBars,
  App.SystemBars.Android.Types,
  App.SystemBars.Android.Interfaces;

type
  { TSystemBarsEventListener }

  TSystemBarsEventListener = class(TInterfacedObject, ISystemBarsEventListener)
  strict private
    type
      TOnApplyWindowInsetsListener = class(TJavaLocal, JView_OnApplyWindowInsetsListener)
      strict private
        FEventListener: ISystemBarsEventListener;
      public
        constructor Create(const AEventListener: ISystemBarsEventListener);
        function onApplyWindowInsets(v: JView; insets: JWindowInsets): JWindowInsets; cdecl;
      end;

      TOnAttachStateChangeListener = class(TJavaLocal, JView_OnAttachStateChangeListener)
      strict private
        FVisibilityController: ISystemBarsVisibilityController;
      public
        constructor Create(const AVisibilityController: ISystemBarsVisibilityController);
        procedure onViewAttachedToWindow(v: JView); cdecl;
        procedure onViewDetachedFromWindow(v: JView); cdecl;
      end;

      TOnWindowFocusChangeListener = class(TJavaLocal, JViewTreeObserver_OnWindowFocusChangeListener)
      strict private
        FVisibilityController: ISystemBarsVisibilityController;
      public
        constructor Create(const AVisibilityController: ISystemBarsVisibilityController);
        procedure onWindowFocusChanged(hasFocus: Boolean); cdecl;
      end;

      TOnTouchListener = class(TJavaLocal, JView_OnTouchListener)
      strict private
        FInsetsCalculator: ISystemBarsInsetsCalculator;
      public
        constructor Create(const AInsetsCalculator: ISystemBarsInsetsCalculator);
        function onTouch(v: JView; event: JMotionEvent): Boolean; cdecl;
      end;
  strict private
    FAfterCreateFormHandleMessageId: Integer;
    FBeforeDestroyFormHandleMessageId: Integer;
    FChangeChecksEnabled: Boolean;
    FFormActivateMessageId: Integer;
    FFormReleasedMessageId: Integer;
    FVirtualKeyboardMessageId: Integer;
    FOnApplyWindowInsetsListener: TOnApplyWindowInsetsListener;
    FOnAttachStateChangeListener: TOnAttachStateChangeListener;
    FOnTouchListener: TOnTouchListener;
    FOnWindowFocusChangeListener: TOnWindowFocusChangeListener;
    FInsetsCalculator: ISystemBarsInsetsCalculator;
    FVisibilityController: ISystemBarsVisibilityController;

    procedure AfterCreateFormHandle(const ASender: TObject; const AMessage: TMessage);
    procedure ApplicationEventHandler(const ASender: TObject; const AMessage: TMessage);
    procedure BeforeDestroyFormHandle(const ASender: TObject; const AMessage: TMessage);
    procedure FormActivate(const ASender: TObject; const AMessage: TMessage);
    procedure FormReleased(const ASender: TObject; const AMessage: TMessage);
    procedure VirtualKeyboardChangeHandler(const ASender: TObject; const AMessage: System.Messaging.TMessage);
  public
    constructor Create(const AInsetsCalculator: ISystemBarsInsetsCalculator = nil;
      const AVisibilityController: ISystemBarsVisibilityController = nil);
    destructor Destroy; override;
    { ISystemBarsEventListener }
    procedure StartListening;
    procedure StopListening;
    procedure CheckInsetsChanges(const AForm: TCommonCustomForm);
    procedure SetChangeChecksEnabled(const AValue: Boolean);
    function GetChangeChecksEnabled: Boolean;
  end;

{$ELSE}
implementation
{$ENDIF}

{$IFDEF ANDROID}
implementation

{ TSystemBarsEventListener.TOnApplyWindowInsetsListener }

constructor TSystemBarsEventListener.TOnApplyWindowInsetsListener.Create(const AEventListener: ISystemBarsEventListener);
begin
  inherited Create;
  FEventListener := AEventListener;
end;

function TSystemBarsEventListener.TOnApplyWindowInsetsListener.onApplyWindowInsets(v: JView; insets: JWindowInsets): JWindowInsets;
var
  LForm: TCommonCustomForm;
begin
  Result := v.OnApplyWindowInsets(insets);
  if Assigned(FEventListener) and FEventListener.GetChangeChecksEnabled and Assigned(Screen) then
  begin
    LForm := Screen.ActiveForm;
    if Assigned(LForm) then
      FEventListener.CheckInsetsChanges(LForm);
  end;
end;

{ TSystemBarsEventListener.TOnAttachStateChangeListener }

constructor TSystemBarsEventListener.TOnAttachStateChangeListener.Create(const AVisibilityController: ISystemBarsVisibilityController);
begin
  inherited Create;
  FVisibilityController := AVisibilityController;
end;

procedure TSystemBarsEventListener.TOnAttachStateChangeListener.onViewAttachedToWindow(v: JView);
var
  LForm: TCommonCustomForm;
  LFormSystemBars: TScreenSystemBars;
begin
  if Assigned(FVisibilityController) and Assigned(Screen) then
  begin
    LForm := Screen.ActiveForm;
    if Assigned(LForm) then
    begin
      LFormSystemBars := LForm.SystemBars;
      if Assigned(LFormSystemBars) then
        FVisibilityController.SetVisibility(LForm, LFormSystemBars.Visibility);
    end;
  end;
end;

procedure TSystemBarsEventListener.TOnAttachStateChangeListener.onViewDetachedFromWindow(v: JView);
begin
end;

{ TSystemBarsEventListener.TOnWindowFocusChangeListener }

constructor TSystemBarsEventListener.TOnWindowFocusChangeListener.Create(const AVisibilityController: ISystemBarsVisibilityController);
begin
  inherited Create;
  FVisibilityController := AVisibilityController;
end;

procedure TSystemBarsEventListener.TOnWindowFocusChangeListener.onWindowFocusChanged(hasFocus: Boolean);
begin
  if hasFocus and Assigned(FVisibilityController) then
    FVisibilityController.TryFixInvisibleMode;
end;

{ TSystemBarsEventListener.TOnTouchListener }

constructor TSystemBarsEventListener.TOnTouchListener.Create(const AInsetsCalculator: ISystemBarsInsetsCalculator);
begin
  inherited Create;
  FInsetsCalculator := AInsetsCalculator;
end;

function TSystemBarsEventListener.TOnTouchListener.onTouch(v: JView; event: JMotionEvent): Boolean;
var
  LForm: TCommonCustomForm;
  LFormSystemBars: TScreenSystemBars;
  LTouchPoint: TPointF;
  LBottomInsets: Single;
begin
  Result := False;
  if TOSVersion.Check(10) and // Android 10 (api level 29) or later
    Assigned(event) and (event.getAction = TJMotionEvent.JavaClass.ACTION_DOWN) then
  begin
    if Assigned(FInsetsCalculator) and Assigned(Screen) then
    begin
      LForm := Screen.ActiveForm;
      if Assigned(LForm) then
      begin
        LFormSystemBars := LForm.SystemBars;
        if Assigned(LFormSystemBars) and (LFormSystemBars.Visibility <> TScreenSystemBars.TVisibilityMode.Invisible) then
        begin
          LBottomInsets := LFormSystemBars.Insets.Bottom;
          if (LBottomInsets > 0) and FInsetsCalculator.HasGestureNavigationBar(LForm) then
          begin
            LTouchPoint := ConvertPixelToPoint(TPointF.Create(event.getRawX, event.getRawY));
            LTouchPoint := LForm.ScreenToClient(LTouchPoint);
            Result := LTouchPoint.Y > LForm.Height - LBottomInsets;
          end;
        end;
      end;
    end;
  end;
end;

{ TSystemBarsEventListener }

constructor TSystemBarsEventListener.Create(const AInsetsCalculator: ISystemBarsInsetsCalculator;
  const AVisibilityController: ISystemBarsVisibilityController);
begin
  inherited Create;
  FInsetsCalculator := AInsetsCalculator;
  FVisibilityController := AVisibilityController;
  FChangeChecksEnabled := True;
end;

destructor TSystemBarsEventListener.Destroy;
begin
  StopListening;
  inherited;
end;

procedure TSystemBarsEventListener.StartListening;
begin
  FAfterCreateFormHandleMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TAfterCreateFormHandle,
    AfterCreateFormHandle);
  FBeforeDestroyFormHandleMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TBeforeDestroyFormHandle,
    BeforeDestroyFormHandle);
  FFormActivateMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TFormActivateMessage, FormActivate);
  FFormReleasedMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TFormReleasedMessage, FormReleased);
  FVirtualKeyboardMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TVKStateChangeMessage,
    VirtualKeyboardChangeHandler);
  TMessageManager.DefaultManager.SubscribeToMessage(TApplicationEventMessage, ApplicationEventHandler);
end;

procedure TSystemBarsEventListener.StopListening;
var
  LViewGroup: JViewGroup;
begin
  TMessageManager.DefaultManager.Unsubscribe(TApplicationEventMessage, ApplicationEventHandler);
  TMessageManager.DefaultManager.Unsubscribe(TVKStateChangeMessage, FVirtualKeyboardMessageId);
  TMessageManager.DefaultManager.Unsubscribe(TAfterCreateFormHandle, FAfterCreateFormHandleMessageId);
  TMessageManager.DefaultManager.Unsubscribe(TBeforeDestroyFormHandle, FBeforeDestroyFormHandleMessageId);
  TMessageManager.DefaultManager.Unsubscribe(TFormReleasedMessage, FFormReleasedMessageId);
  TMessageManager.DefaultManager.Unsubscribe(TFormActivateMessage, FFormActivateMessageId);

  if Assigned(FOnAttachStateChangeListener) then
  begin
    LViewGroup := GetMainActivityContentView;
    if Assigned(LViewGroup) then
    begin
      if Assigned(FOnApplyWindowInsetsListener) then
        LViewGroup.setOnApplyWindowInsetsListener(nil);
      LViewGroup.removeOnAttachStateChangeListener(FOnAttachStateChangeListener);
      if Assigned(FOnWindowFocusChangeListener) then
        LViewGroup.getViewTreeObserver.removeOnWindowFocusChangeListener(FOnWindowFocusChangeListener);
    end;
    FreeAndNil(FOnApplyWindowInsetsListener);
    FreeAndNil(FOnAttachStateChangeListener);
    FreeAndNil(FOnWindowFocusChangeListener);
  end;
  FreeAndNil(FOnTouchListener);
end;

procedure TSystemBarsEventListener.AfterCreateFormHandle(const ASender: TObject; const AMessage: TMessage);

  procedure TryApplyInsetsListener;
  var
    LViewGroup: JViewGroup;
  begin
    LViewGroup := GetMainActivityContentView;
    if Assigned(LViewGroup) then
    begin
      {$IF CompilerVersion < 34.0} // Delphi Sydney 10.4
      if TJBuild_VERSION.JavaClass.SDK_INT >= 20 then // Android 4.4W (Kitkat Watch / api level 20) or later
      {$IFEND}
      begin
        FOnApplyWindowInsetsListener := TOnApplyWindowInsetsListener.Create(Self);
        LViewGroup.setOnApplyWindowInsetsListener(FOnApplyWindowInsetsListener);
      end;
      FOnAttachStateChangeListener := TOnAttachStateChangeListener.Create(FVisibilityController);
      LViewGroup.addOnAttachStateChangeListener(FOnAttachStateChangeListener);
      {$IF CompilerVersion < 34.0} // Delphi Sydney 10.4
      if TOSVersion.Check(4, 3) then // Android 4.3 (Jelly Bean / api level 18) or later
      {$IFEND}
      begin
        FOnWindowFocusChangeListener := TOnWindowFocusChangeListener.Create(FVisibilityController);
        LViewGroup.getViewTreeObserver.addOnWindowFocusChangeListener(FOnWindowFocusChangeListener);
      end;
    end;
    if not Assigned(FOnTouchListener) then
      FOnTouchListener := TOnTouchListener.Create(FInsetsCalculator);
  end;

var
  LForm: TCommonCustomForm;
begin
  if not Assigned(FOnAttachStateChangeListener) then
    TryApplyInsetsListener;
  if ASender is TCommonCustomForm then
  begin
    LForm := TCommonCustomForm(ASender);
    if LForm.IsHandleAllocated then
      TAndroidWindowHandle(LForm.Handle).View.setOnTouchListener(FOnTouchListener);
    CheckInsetsChanges(LForm);
  end;
end;

procedure TSystemBarsEventListener.ApplicationEventHandler(const ASender: TObject; const AMessage: TMessage);
begin
  if (AMessage is TApplicationEventMessage) and (TApplicationEventMessage(AMessage).Value.Event = TApplicationEvent.BecameActive) then
  begin
    TThread.CreateAnonymousThread(
      procedure
      begin
        Sleep(1000);
        TThread.CurrentThread.ForceQueue(nil,
          procedure
          begin
            if Assigned(FVisibilityController) then
              FVisibilityController.TryFixInvisibleMode;
          end);
      end).Start;
  end;
end;

procedure TSystemBarsEventListener.BeforeDestroyFormHandle(const ASender: TObject; const AMessage: TMessage);
var
  LForm: TCommonCustomForm;
begin
  if ASender is TCommonCustomForm then
  begin
    LForm := TCommonCustomForm(ASender);
    if LForm.IsHandleAllocated then
      TAndroidWindowHandle(LForm.Handle).View.setOnTouchListener(nil);
  end;
end;

procedure TSystemBarsEventListener.CheckInsetsChanges(const AForm: TCommonCustomForm);
var
  LNewInsets: TRectF;
  LNewTappableInsets: TRectF;
  LFormSystemBars: TScreenSystemBars;
begin
  if Assigned(AForm) and AForm.Active then
  begin
    LFormSystemBars := AForm.SystemBars;
    if Assigned(LFormSystemBars) and Assigned(FInsetsCalculator) then
    begin
      LNewInsets := FInsetsCalculator.GetInsets(AForm);
      LNewTappableInsets := FInsetsCalculator.GetTappableInsets(AForm);
      if (not LNewInsets.EqualsTo(LFormSystemBars.Insets, TEpsilon.Position)) or
        (not LNewTappableInsets.EqualsTo(LFormSystemBars.TappableInsets, TEpsilon.Position)) then
      begin
        TMessageManager.DefaultManager.SendMessage(AForm, TScreenSystemBars.TInsetsChangeMessage.Create(LNewInsets,
          LNewTappableInsets));
        TThread.ForceQueue(nil,
          procedure()
          begin
            if Assigned(Screen) and (Screen.ActiveForm = AForm) and Assigned(FVisibilityController) then
              FVisibilityController.SetVisibility(AForm, AForm.SystemBars.Visibility);
          end);
      end;
    end;
  end;
end;

procedure TSystemBarsEventListener.FormActivate(const ASender: TObject; const AMessage: TMessage);
var
  LForm: TCommonCustomForm;
begin
  if ASender is TCommonCustomForm then
  begin
    LForm := TCommonCustomForm(ASender);
    if Assigned(FVisibilityController) then
      FVisibilityController.SetVisibility(LForm, LForm.SystemStatusBar.Visibility);
  end;
end;

procedure TSystemBarsEventListener.FormReleased(const ASender: TObject; const AMessage: TMessage);
begin
  if (ASender is TCommonCustomForm) and Assigned(FVisibilityController) then
    FVisibilityController.FormReleased(TCommonCustomForm(ASender));
end;

function TSystemBarsEventListener.GetChangeChecksEnabled: Boolean;
begin
  Result := FChangeChecksEnabled;
end;

procedure TSystemBarsEventListener.SetChangeChecksEnabled(const AValue: Boolean);
begin
  FChangeChecksEnabled := AValue;
end;

procedure TSystemBarsEventListener.VirtualKeyboardChangeHandler(const ASender: TObject; const AMessage: System.Messaging.TMessage);
var
  LBounds: TRect;
begin
  if AMessage is TVKStateChangeMessage then
  begin
    if TVKStateChangeMessage(AMessage).KeyboardVisible then
    begin
      LBounds := TVKStateChangeMessage(AMessage).KeyboardBounds;
      if LBounds.IsEmpty then
        LBounds := TRect.Empty;
    end
    else
      LBounds := TRect.Empty;

    if Assigned(FInsetsCalculator) then
      FInsetsCalculator.SetVirtualKeyboardBounds(LBounds);

    if Assigned(Screen) then
      CheckInsetsChanges(Screen.ActiveForm);

    if (LBounds = TRect.Empty) and Assigned(FVisibilityController) then
      FVisibilityController.TryFixInvisibleMode;
  end;
end;

{$ENDIF}

end.
