unit App.SystemBars.Android.ColorController;

interface

{$SCOPEDENUMS ON}
{$IFDEF ANDROID}

uses
  { Delphi }
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.UIConsts,
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
  { TSystemBarsColorController }

  TSystemBarsColorController = class(TInterfacedObject, ISystemBarsColorController)
  strict private
    FInsetsCalculator: ISystemBarsInsetsCalculator;
    procedure RefreshView(const AView: JView);
    function CanFormChangeSystemBars(const AForm: TCommonCustomForm): Boolean;
    function HasGestureNavigationBar(const AForm: TCommonCustomForm): Boolean;
  public
    constructor Create(const AInsetsCalculator: ISystemBarsInsetsCalculator = nil);
    { ISystemBarsColorController }
    procedure SetStatusBarBackgroundColor(const AForm: TCommonCustomForm; const AColor: TAlphaColor);
    procedure SetNavigationBarBackgroundColor(const AForm: TCommonCustomForm; const AColor: TAlphaColor);
  end;

{$ELSE}
implementation
{$ENDIF}

{$IFDEF ANDROID}
implementation

{ TSystemBarsColorController }

constructor TSystemBarsColorController.Create(const AInsetsCalculator: ISystemBarsInsetsCalculator);
begin
  inherited Create;
  FInsetsCalculator := AInsetsCalculator;
end;

function TSystemBarsColorController.CanFormChangeSystemBars(const AForm: TCommonCustomForm): Boolean;
begin
  Result := Assigned(AForm) and AForm.IsHandleAllocated and AForm.Active;
end;

function TSystemBarsColorController.HasGestureNavigationBar(const AForm: TCommonCustomForm): Boolean;
begin
  if Assigned(FInsetsCalculator) then
    Result := FInsetsCalculator.HasGestureNavigationBar(AForm)
  else if TOSVersion.Check(10) then
    Result := Assigned(AForm) and AForm.IsHandleAllocated and AForm.Active and
      (AForm.SystemBars.Visibility <> TScreenSystemBars.TVisibilityMode.Invisible)
  else
    Result := False;
end;

procedure TSystemBarsColorController.RefreshView(const AView: JView);
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

procedure TSystemBarsColorController.SetNavigationBarBackgroundColor(const AForm: TCommonCustomForm; const AColor: TAlphaColor);
var
  LNavigationBarLight: Boolean;
  LNavigationBarJColor: Integer;
  LActivity: JActivity;
  LWindow: JWindow;
  LWindowAndroid10: TAndroid10.JWindow;
  LView: JFormView;
  LViewAndroid11: TAndroid11.JView;
  LWindowInsetsController: TAndroid11.JWindowInsetsController;
  LSystemUiVisibility: Integer;
  LNewAlphaColor: TAlphaColor;
begin
  {$IF CompilerVersion < 34.0} // Delphi Sydney 10.4
  if not TOSVersion.Check(5) then // Supported only Android 5.0 (Lollipop / api level 21) or later
    Exit;
  {$IFEND}
  if not CanFormChangeSystemBars(AForm) then
    Exit;

  LNewAlphaColor := AColor;
  case AForm.SystemBars.Visibility of
    TScreenSystemBars.TVisibilityMode.Visible:
      begin
        if AColor = TAlphaColors.Null then // Like iOS
        begin
          // BEFORE the Android 8.0 (api level 26), the navigation bar buttons is always
          // white, then is better set the background color to black as default
          if IsDarkTheme or not TOSVersion.Check(8) then
            LNewAlphaColor := TAlphaColors.Black
          else
            LNewAlphaColor := TAlphaColors.White;
        end;
        if HasGestureNavigationBar(AForm) then
          TAlphaColorRec(LNewAlphaColor).A := 0;
      end;
    TScreenSystemBars.TVisibilityMode.VisibleAndOverlap:
      if HasGestureNavigationBar(AForm) then
        TAlphaColorRec(LNewAlphaColor).A := 0;
    TScreenSystemBars.TVisibilityMode.Invisible:
      TAlphaColorRec(LNewAlphaColor).A := 0;
  end;

  LNavigationBarLight := Luminance(LNewAlphaColor) > 0.5;
  LNavigationBarJColor := TAndroidHelper.AlphaColorToJColor(LNewAlphaColor);
  LActivity := TAndroidHelper.Activity;
  if Assigned(LActivity) then
    LWindow := LActivity.getWindow
  else
    LWindow := nil;
  if AForm.IsHandleAllocated then
    LView := TAndroidWindowHandle(AForm.Handle).View
  else
    LView := nil;

  if TOSVersion.Check(11) then // Android 11 (api level 30) or later
  begin
    if Assigned(LWindow) then
    begin
      LWindowAndroid10 := TAndroid10.TJWindow.Wrap(TAndroidHelper.JObjectToID(LWindow));
      if Assigned(LWindowAndroid10) then
        LWindowAndroid10.setNavigationBarContrastEnforced(False);
      if LWindow.getNavigationBarColor <> LNavigationBarJColor then
      begin
        LWindow.setNavigationBarColor(LNavigationBarJColor);
        RefreshView(LView);
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
          if LNavigationBarLight then
            LWindowInsetsController.setSystemBarsAppearance(TAndroid11.TJWindowInsetsController.JavaClass.APPEARANCE_LIGHT_NAVIGATION_BARS,
              TAndroid11.TJWindowInsetsController.JavaClass.APPEARANCE_LIGHT_NAVIGATION_BARS)
          else
            LWindowInsetsController.setSystemBarsAppearance(0, TAndroid11.TJWindowInsetsController.JavaClass.APPEARANCE_LIGHT_NAVIGATION_BARS);
        end;
      end;
    end;
  end
  else // BEFORE Android 11 (api level 30)
  begin
    if TOSVersion.Check(8) and Assigned(LView) then // Android 8.0 (Oreo / api level 26) or later
    begin
      if LNavigationBarLight then
        LSystemUiVisibility := LView.getSystemUiVisibility or TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
      else
        LSystemUiVisibility := LView.getSystemUiVisibility and not TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
      LView.setSystemUiVisibility(LSystemUiVisibility);
    end;
    if TOSVersion.Check(10) and Assigned(LWindow) then // Android 10 (api level 29) or later
    begin
      LWindowAndroid10 := TAndroid10.TJWindow.Wrap(TAndroidHelper.JObjectToID(LWindow));
      if Assigned(LWindowAndroid10) then
        LWindowAndroid10.setNavigationBarContrastEnforced(False);
    end;
    if Assigned(LWindow)
      {$IF CompilerVersion < 34.0} // Delphi Sydney 10.4
      and TOSVersion.Check(5)
      {$IFEND} then // Android 5.0 (Lollipop / api level 21) or later
    begin
      if LWindow.getNavigationBarColor <> LNavigationBarJColor then
      begin
        LWindow.setNavigationBarColor(LNavigationBarJColor);
        RefreshView(LView);
      end;
    end;
  end;
end;

procedure TSystemBarsColorController.SetStatusBarBackgroundColor(const AForm: TCommonCustomForm; const AColor: TAlphaColor);
var
  LStatusBarLight: Boolean;
  LStatusBarJColor: Integer;
  LActivity: JActivity;
  LWindow: JWindow;
  LWindowAndroid10: TAndroid10.JWindow;
  LView: JFormView;
  LViewAndroid11: TAndroid11.JView;
  LWindowInsetsController: TAndroid11.JWindowInsetsController;
  LSystemUiVisibility: Integer;
  LNewAlphaColor: TAlphaColor;
  LMainActivityContentView: JViewGroup;
begin
  {$IF CompilerVersion < 34.0} // Delphi Sydney 10.4
  if not TOSVersion.Check(5) then // Supported only Android 5.0 (Lollipop / api level 21) or later
    Exit;
  {$IFEND}
  if not CanFormChangeSystemBars(AForm) then
    Exit;

  LNewAlphaColor := AColor;
  case AForm.SystemBars.Visibility of
    TScreenSystemBars.TVisibilityMode.Visible:
      if AColor = TAlphaColors.Null then // Like iOS
      begin
        if IsDarkTheme then
          LNewAlphaColor := TAlphaColors.Black
        else
          LNewAlphaColor := TAlphaColors.White;
      end;
    TScreenSystemBars.TVisibilityMode.VisibleAndOverlap:
      ;
    TScreenSystemBars.TVisibilityMode.Invisible:
      TAlphaColorRec(LNewAlphaColor).A := 0;
  end;

  LStatusBarLight := Luminance(LNewAlphaColor) > 0.5;
  LStatusBarJColor := TAndroidHelper.AlphaColorToJColor(LNewAlphaColor);
  LActivity := TAndroidHelper.Activity;
  if Assigned(LActivity) then
    LWindow := LActivity.getWindow
  else
    LWindow := nil;
  if AForm.IsHandleAllocated then
    LView := TAndroidWindowHandle(AForm.Handle).View
  else
    LView := nil;

  // Setting the configurations
  if TOSVersion.Check(11) then // Android 11 (api level 30) or later
  begin
    if Assigned(LWindow) then
    begin
      LWindowAndroid10 := TAndroid10.TJWindow.Wrap(TAndroidHelper.JObjectToID(LWindow));
      if Assigned(LWindowAndroid10) then
        LWindowAndroid10.setStatusBarContrastEnforced(False);
      if LWindow.getStatusBarColor <> LStatusBarJColor then
      begin
        LWindow.setStatusBarColor(LStatusBarJColor);
        RefreshView(LView);
      end;
    end;
    if Assigned(LView) then
    begin
      if TOSVersion.Check(11) then
      begin
        LViewAndroid11 := TAndroid11.TJView.Wrap(TAndroidHelper.JObjectToID(LView));
        if Assigned(LViewAndroid11) then
        begin
          LWindowInsetsController := LViewAndroid11.getWindowInsetsController;
          if Assigned(LWindowInsetsController) then
          begin
            if LStatusBarLight then
              LWindowInsetsController.setSystemBarsAppearance(TAndroid11.TJWindowInsetsController.JavaClass.APPEARANCE_LIGHT_STATUS_BARS,
                TAndroid11.TJWindowInsetsController.JavaClass.APPEARANCE_LIGHT_STATUS_BARS)
            else
              LWindowInsetsController.setSystemBarsAppearance(0, TAndroid11.TJWindowInsetsController.JavaClass.APPEARANCE_LIGHT_STATUS_BARS);
          end;
        end;
      end;
      if LStatusBarLight then
        LSystemUiVisibility := LView.getSystemUiVisibility or TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
      else
        LSystemUiVisibility := LView.getSystemUiVisibility and not TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
      LView.setSystemUiVisibility(LSystemUiVisibility);
    end;
  end
  else // BEFORE Android 11 (api level 30)
  begin
    if TOSVersion.Check(6) and Assigned(LView) then // Android 6 (Marshmallow / api level 23) or later
    begin
      if LStatusBarLight then
        LSystemUiVisibility := LView.getSystemUiVisibility or TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
      else
        LSystemUiVisibility := LView.getSystemUiVisibility and not TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
      LView.setSystemUiVisibility(LSystemUiVisibility);
    end;
    if TOSVersion.Check(10) and Assigned(LWindow) then // Android 10 (api level 29) or later
    begin
      LWindowAndroid10 := TAndroid10.TJWindow.Wrap(TAndroidHelper.JObjectToID(LWindow));
      if Assigned(LWindowAndroid10) then
        LWindowAndroid10.setStatusBarContrastEnforced(False);
    end;
    if Assigned(LWindow)
      {$IF CompilerVersion < 34.0} // Delphi Sydney 10.4
      and TOSVersion.Check(5)
      {$IFEND} then // Android 5.0 (Lollipop / api level 21) or later
    begin
      if LWindow.getStatusBarColor <> LStatusBarJColor then
      begin
        LWindow.setStatusBarColor(LStatusBarJColor);
        RefreshView(LView);
      end;
    end;
  end;

  if AForm.Active and (AForm.SystemBars.Visibility = TScreenSystemBars.TVisibilityMode.Visible) and HasGestureNavigationBar(AForm) then
  begin
    LMainActivityContentView := GetMainActivityContentView;
    if Assigned(LMainActivityContentView) then
      LMainActivityContentView.setBackgroundColor(TAndroidHelper.AlphaColorToJColor(TAlphaColors.White));
  end;
end;

{$ENDIF}

end.
