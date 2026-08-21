unit App.SystemBars.Android.VisibilityController;

interface

{$SCOPEDENUMS ON}
{$IFDEF ANDROID}

uses
  { Delphi }
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Generics.Collections,
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
  { TSystemBarsVisibilityController }

  TSystemBarsVisibilityController = class(TInterfacedObject, ISystemBarsVisibilityController)
  strict private
    FDefaultFormVisibility: TDictionary<TCommonCustomForm, TScreenSystemBars.TVisibilityMode>;
    FColorController: ISystemBarsColorController;
    FInsetsCalculator: ISystemBarsInsetsCalculator;
    procedure RefreshView(const AView: JView);
    function CanFormChangeSystemBars(const AForm: TCommonCustomForm): Boolean;
    function HasGestureNavigationBar(const AForm: TCommonCustomForm): Boolean;
  public
    constructor Create(const AColorController: ISystemBarsColorController = nil;
      const AInsetsCalculator: ISystemBarsInsetsCalculator = nil);
    destructor Destroy; override;
    { ISystemBarsVisibilityController }
    procedure SetVisibility(const AForm: TCommonCustomForm; const AMode: TScreenSystemBars.TVisibilityMode);
    procedure DoSetVisibility(const AForm: TCommonCustomForm; const AMode: TScreenSystemBars.TVisibilityMode);
    function GetFullScreen(const AForm: TCommonCustomForm): Boolean;
    procedure SetFullScreen(const AForm: TCommonCustomForm; const AValue: Boolean);
    procedure SetShowFullScreenIcon(const AForm: TCommonCustomForm; const AValue: Boolean);
    procedure TryFixInvisibleMode;
    procedure FormReleased(const AForm: TCommonCustomForm);
  end;

{$ELSE}
implementation
{$ENDIF}

{$IFDEF ANDROID}
implementation

{ TSystemBarsVisibilityController }

constructor TSystemBarsVisibilityController.Create(const AColorController: ISystemBarsColorController;
  const AInsetsCalculator: ISystemBarsInsetsCalculator);
begin
  inherited Create;
  FColorController := AColorController;
  FInsetsCalculator := AInsetsCalculator;
  FDefaultFormVisibility := TDictionary<TCommonCustomForm, TScreenSystemBars.TVisibilityMode>.Create;
end;

destructor TSystemBarsVisibilityController.Destroy;
begin
  FreeAndNil(FDefaultFormVisibility);
  inherited;
end;

function TSystemBarsVisibilityController.CanFormChangeSystemBars(const AForm: TCommonCustomForm): Boolean;
begin
  Result := Assigned(AForm) and AForm.IsHandleAllocated and AForm.Active;
end;

function TSystemBarsVisibilityController.HasGestureNavigationBar(const AForm: TCommonCustomForm): Boolean;
begin
  if Assigned(FInsetsCalculator) then
    Result := FInsetsCalculator.HasGestureNavigationBar(AForm)
  else
    Result := False;
end;

procedure TSystemBarsVisibilityController.RefreshView(const AView: JView);
var
  LViewParent: JViewParent;
begin
  if Assigned(AView) then
  begin
    LViewParent := AView.getParent;
    if Assigned(LViewParent) then
    begin
      LViewParent.requestFitSystemWindows;
      LViewParent.requestLayout;
    end;
  end;
end;

procedure TSystemBarsVisibilityController.DoSetVisibility(const AForm: TCommonCustomForm; const AMode: TScreenSystemBars.TVisibilityMode);
var
  LActivity: JActivity;
  LWindow: JWindow;
  LWindowAndroid11: TAndroid11.JWindow;
  LView: JFormView;
  LMainActivityContentView: JViewGroup;
  LViewAndroid11: TAndroid11.JView;
  LWindowInsetsController: TAndroid11.JWindowInsetsController;
  LSystemUiVisibility: Integer;
  LSystemUiVisibilityMask: Integer;
  LWinParams: JWindowManager_LayoutParams;
  LWinParamsAndroid9: TAndroid9.JWindowManager_LayoutParams;
  LHasGestureNavigationBar: Boolean;
  LRect: TRect;
begin
  {$IF CompilerVersion < 34.0} // Delphi Sydney 10.4
  if not TOSVersion.Check(4, 4) then // Supported only Android 4.4 (Kitkat / api level 19) or later
    Exit;
  {$IFEND}
  if not CanFormChangeSystemBars(AForm) then
    Exit;

  LWindow := nil;
  LActivity := TAndroidHelper.Activity;
  if Assigned(LActivity) then
    LWindow := LActivity.getWindow;
  if AForm.IsHandleAllocated then
    LView := TAndroidWindowHandle(AForm.Handle).View
  else
    LView := nil;
  LHasGestureNavigationBar := HasGestureNavigationBar(AForm);

  if Assigned(FColorController) then
  begin
    FColorController.SetStatusBarBackgroundColor(AForm, AForm.SystemStatusBar.BackgroundColor);
    FColorController.SetNavigationBarBackgroundColor(AForm, AForm.SystemBars.NavigationBarBackgroundColor);
  end;

  if TOSVersion.Check(11) then // Android 11 (api level 30) or later
  begin
    if Assigned(LWindow) then
    begin
      LWindowAndroid11 := TAndroid11.TJWindowEx.Wrap((LWindow as ILocalObject).GetObjectID);
      if Assigned(LWindowAndroid11) then
        LWindowAndroid11.setDecorFitsSystemWindows((AMode = TScreenSystemBars.TVisibilityMode.Visible) and not
          LHasGestureNavigationBar);
      LWinParams := LWindow.getAttributes;
      if Assigned(LWinParams) then
      begin
        LWinParamsAndroid9 := TAndroid9.TJWindowManager_LayoutParams.Wrap(TAndroidHelper.JObjectToID(LWinParams));
        if Assigned(LWinParamsAndroid9) then
        begin
          if AMode = TScreenSystemBars.TVisibilityMode.Invisible then
            LWinParamsAndroid9.layoutInDisplayCutoutMode := TAndroid9.TJWindowManager_LayoutParams.JavaClass.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
          else
            LWinParamsAndroid9.layoutInDisplayCutoutMode := TAndroid9.TJWindowManager_LayoutParams.JavaClass.LAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT;
        end;
        LWindow.setAttributes(LWinParams);
      end;
    end;

    if Assigned(LView) then
    begin
      LViewAndroid11 := TAndroid11.TJView.Wrap(TAndroidHelper.JObjectToID(LView));
      if Assigned(LViewAndroid11) then
      begin
        LWindowInsetsController := LViewAndroid11.getWindowInsetsController;
        if Assigned(LWindowInsetsController) then
        begin
          case AMode of
            TScreenSystemBars.TVisibilityMode.Visible, TScreenSystemBars.TVisibilityMode.VisibleAndOverlap:
              begin
                LWindowInsetsController.show(TAndroid11.TJWindowInsets_Type.JavaClass.statusBars or
                  TAndroid11.TJWindowInsets_Type.JavaClass.navigationBars);
              end;
            TScreenSystemBars.TVisibilityMode.Invisible:
              begin
                LWindowInsetsController.setSystemBarsBehavior(TAndroid11.TJWindowInsetsController.JavaClass.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
                LWindowInsetsController.hide(TAndroid11.TJWindowInsets_Type.JavaClass.statusBars or
                  TAndroid11.TJWindowInsets_Type.JavaClass.navigationBars);
              end;
          end;
        end;
      end;
    end;

    if Assigned(FColorController) then
    begin
      FColorController.SetStatusBarBackgroundColor(AForm, AForm.SystemStatusBar.BackgroundColor);
      FColorController.SetNavigationBarBackgroundColor(AForm, AForm.SystemBars.NavigationBarBackgroundColor);
    end;
  end
  else // BEFORE Android 11 (api level 30)
  begin
    LSystemUiVisibilityMask := 0;
    if Assigned(LWindow) then
      LWinParams := LWindow.getAttributes
    else
      LWinParams := nil;

    {$IF CompilerVersion < 34.0} // Delphi Sydney 10.4
    if TOSVersion.Check(4, 4) and not TOSVersion.Check(5) and // Android 4.4 (Kitkat / api level 19) and Android 4.4W (Kitkat Watch / api level 20)
      Assigned(LWinParams) then
    begin
      case AMode of
        TScreenSystemBars.TVisibilityMode.Visible:
          begin
            LWinParams.flags := LWinParams.flags and not
              (TJWindowManager_LayoutParams.JavaClass.FLAG_TRANSLUCENT_STATUS or
              TJWindowManager_LayoutParams.JavaClass.FLAG_TRANSLUCENT_NAVIGATION);
          end;
        TScreenSystemBars.TVisibilityMode.VisibleAndOverlap:
          begin
            LWinParams.flags := LWinParams.flags or
              TJWindowManager_LayoutParams.JavaClass.FLAG_TRANSLUCENT_STATUS or
              TJWindowManager_LayoutParams.JavaClass.FLAG_TRANSLUCENT_NAVIGATION;
          end;
        TScreenSystemBars.TVisibilityMode.Invisible:
          ;
      end;
    end;
    {$IFEND}
    if Assigned(LWinParams)
      {$IF CompilerVersion < 34.0} // Delphi Sydney 10.4
      and TOSVersion.Check(5)
      {$IFEND} then // Android 5.0 (Lollipop / api level 21) or later
    begin
      LWinParams.flags := LWinParams.flags and not
        (TJWindowManager_LayoutParams.JavaClass.FLAG_TRANSLUCENT_STATUS or
        TJWindowManager_LayoutParams.JavaClass.FLAG_TRANSLUCENT_NAVIGATION);
    end;
    if Assigned(LWinParams) then
    begin
      if TOSVersion.Check(9) then // Android 9 (Pie / api level 28) or later
      begin
        LWinParamsAndroid9 := TAndroid9.TJWindowManager_LayoutParams.Wrap(TAndroidHelper.JObjectToID(LWinParams));
        if Assigned(LWinParamsAndroid9) then
        begin
          if AMode = TScreenSystemBars.TVisibilityMode.Invisible then
            LWinParamsAndroid9.layoutInDisplayCutoutMode := TAndroid9.TJWindowManager_LayoutParams.JavaClass.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
          else
            LWinParamsAndroid9.layoutInDisplayCutoutMode := TAndroid9.TJWindowManager_LayoutParams.JavaClass.LAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT;
        end;
      end;
      if AMode = TScreenSystemBars.TVisibilityMode.Invisible then
        LWinParams.flags := (LWinParams.flags or TJWindowManager_LayoutParams.JavaClass.FLAG_FULLSCREEN)
          and not TJWindowManager_LayoutParams.JavaClass.FLAG_FORCE_NOT_FULLSCREEN
      else
        LWinParams.flags := (LWinParams.flags or TJWindowManager_LayoutParams.JavaClass.FLAG_FORCE_NOT_FULLSCREEN)
          and not TJWindowManager_LayoutParams.JavaClass.FLAG_FULLSCREEN;
      LWindow.setAttributes(LWinParams);
    end;

    if TOSVersion.Check(6) then // Android 6 (Marshmallow / api level 23) or later
      LSystemUiVisibilityMask := LSystemUiVisibilityMask or TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
    if TOSVersion.Check(8) then // Android 8.0 (Oreo / api level 26) or later
      LSystemUiVisibilityMask := LSystemUiVisibilityMask or TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
    if Assigned(LView)
      {$IF CompilerVersion < 34.0} // Delphi Sydney 10.4
      and TOSVersion.Check(4, 4)
      {$IFEND} then // Android 4.4 (Kitkat / api level 19) or later
    begin
      case AMode of
        TScreenSystemBars.TVisibilityMode.Visible:
          begin
            if LHasGestureNavigationBar then
            begin
              LSystemUiVisibility := TJView.JavaClass.SYSTEM_UI_FLAG_VISIBLE or
                TJView.JavaClass.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                TJView.JavaClass.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                TJView.JavaClass.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION;
            end
            else
              LSystemUiVisibility := TJView.JavaClass.SYSTEM_UI_FLAG_VISIBLE;
          end;
        TScreenSystemBars.TVisibilityMode.VisibleAndOverlap:
          begin
            LSystemUiVisibility := TJView.JavaClass.SYSTEM_UI_FLAG_VISIBLE or
              TJView.JavaClass.SYSTEM_UI_FLAG_LAYOUT_STABLE or
              TJView.JavaClass.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
              TJView.JavaClass.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION;
          end;
        TScreenSystemBars.TVisibilityMode.Invisible:
          begin
            LSystemUiVisibility := TJView.JavaClass.SYSTEM_UI_FLAG_LAYOUT_STABLE or
              TJView.JavaClass.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
              TJView.JavaClass.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
              TJView.JavaClass.SYSTEM_UI_FLAG_HIDE_NAVIGATION or // hide nav bar
              TJView.JavaClass.SYSTEM_UI_FLAG_FULLSCREEN or // hide status bar
              TJView.JavaClass.SYSTEM_UI_FLAG_IMMERSIVE_STICKY;
          end;
      else
        LSystemUiVisibility := 0;
      end;
      LView.setSystemUiVisibility((LView.getSystemUiVisibility and LSystemUiVisibilityMask) or LSystemUiVisibility);
    end;
  end;

  if Assigned(LView) then
  begin
    LView.setFitsSystemWindows((AMode = TScreenSystemBars.TVisibilityMode.Visible) and not LHasGestureNavigationBar);
    RefreshView(LView);

    LMainActivityContentView := GetMainActivityContentView;
    if Assigned(LMainActivityContentView) then
    begin
      if HasGestureNavigationBar(AForm) and (AMode = TScreenSystemBars.TVisibilityMode.Visible) and Assigned(FInsetsCalculator) then
      begin
        LRect := FInsetsCalculator.DoGetAbsoluteTappableInsets(AForm);
        LMainActivityContentView.setPadding(LRect.Left, LRect.Top, LRect.Right, LRect.Bottom);
      end
      else
        LMainActivityContentView.setPadding(0, 0, 0, 0);
    end;
  end;

  if AMode <> TScreenSystemBars.TVisibilityMode.Invisible then
    FDefaultFormVisibility.AddOrSetValue(AForm, AMode);

  // Set again when the HasGestureNavigationBar changes due the config
  if LHasGestureNavigationBar <> HasGestureNavigationBar(AForm) then
    DoSetVisibility(AForm, AMode);
end;

procedure TSystemBarsVisibilityController.FormReleased(const AForm: TCommonCustomForm);
begin
  if Assigned(AForm) then
    FDefaultFormVisibility.Remove(AForm);
end;

function TSystemBarsVisibilityController.GetFullScreen(const AForm: TCommonCustomForm): Boolean;
var
  LSystemBars: TScreenSystemBars;
begin
  Result := False;
  if Assigned(AForm) then
  begin
    LSystemBars := AForm.SystemBars;
    if Assigned(LSystemBars) then
      Result := LSystemBars.Visibility = TScreenSystemBars.TVisibilityMode.Invisible;
  end;
end;

procedure TSystemBarsVisibilityController.SetFullScreen(const AForm: TCommonCustomForm; const AValue: Boolean);
var
  LDefaultFormVisibility: TScreenSystemBars.TVisibilityMode;
begin
  if Assigned(AForm) then
  begin
    if AValue then
      AForm.SystemBars.Visibility := TScreenSystemBars.TVisibilityMode.Invisible
    else if GetFullScreen(AForm) then
    begin
      if FDefaultFormVisibility.TryGetValue(AForm, LDefaultFormVisibility) then
        AForm.SystemBars.Visibility := LDefaultFormVisibility
      else
        AForm.SystemBars.Visibility := TScreenSystemBars.DefaultVisibility;
    end;
  end;
end;

procedure TSystemBarsVisibilityController.SetShowFullScreenIcon(const AForm: TCommonCustomForm; const AValue: Boolean);
begin
end;

procedure TSystemBarsVisibilityController.SetVisibility(const AForm: TCommonCustomForm; const AMode: TScreenSystemBars.TVisibilityMode);
begin
  DoSetVisibility(AForm, AMode);
end;

procedure TSystemBarsVisibilityController.TryFixInvisibleMode;
var
  LForm: TCommonCustomForm;
  LFormSystemBars: TScreenSystemBars;
begin
  if Assigned(Screen) then
  begin
    LForm := Screen.ActiveForm;
    if Assigned(LForm) then
    begin
      LFormSystemBars := LForm.SystemBars;
      if Assigned(LFormSystemBars) and (LFormSystemBars.Visibility = TScreenSystemBars.TVisibilityMode.Invisible) then
        SetVisibility(LForm, LFormSystemBars.Visibility);
    end;
  end;
end;

{$ENDIF}

end.
