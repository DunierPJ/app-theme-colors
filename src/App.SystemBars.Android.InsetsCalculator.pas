unit App.SystemBars.Android.InsetsCalculator;

interface

{$SCOPEDENUMS ON}
{$IFDEF ANDROID}

uses
  { Delphi }
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Math,
  FMX.Forms,
  FMX.Types,
  FMX.Platform,
  Androidapi.JNIBridge,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers,
  Androidapi.Jni,
  App.SystemBars,
  App.SystemBars.Android.Types,
  App.SystemBars.Android.Interfaces;

type
  { TSystemBarsInsetsCalculator }

  TSystemBarsInsetsCalculator = class(TInterfacedObject, ISystemBarsInsetsCalculator)
  strict private
    FVirtualKeyboardBounds: TRect;
    function RemoveKeyboardOverlappedBars(const AInsets: TRectF; const AForm: TCommonCustomForm): TRectF;
  public
    constructor Create;
    { ISystemBarsInsetsCalculator }
    function GetInsets(const AForm: TCommonCustomForm): TRectF;
    function GetTappableInsets(const AForm: TCommonCustomForm): TRectF;
    function DoGetAbsoluteInsets(const AForm: TCommonCustomForm): TRect;
    function DoGetAbsoluteTappableInsets(const AForm: TCommonCustomForm): TRect;
    function GetAbsoluteInsets(const AForm: TCommonCustomForm): TRect;
    function GetAbsoluteTappableInsets(const AForm: TCommonCustomForm): TRect;
    function HasGestureNavigationBar(const AForm: TCommonCustomForm): Boolean;
    function HasSystemBars(const AForm: TCommonCustomForm): Boolean;
    procedure SetVirtualKeyboardBounds(const ABounds: TRect);
    function GetVirtualKeyboardBounds: TRect;
  end;

{$ELSE}
implementation
{$ENDIF}

{$IFDEF ANDROID}
implementation

{ TSystemBarsInsetsCalculator }

constructor TSystemBarsInsetsCalculator.Create;
begin
  inherited Create;
  FVirtualKeyboardBounds := TRect.Empty;
end;

function TSystemBarsInsetsCalculator.DoGetAbsoluteInsets(const AForm: TCommonCustomForm): TRect;
var
  LView: JView;
  LWindowInsets: JWindowInsets;
  LWindowInsetsAndroid11: TAndroid11.JWindowInsets;
  LInsets: TAndroid10.JInsets;
begin
  Result := TRect.Empty;
  if TOSVersion.Check(6) then // Android 6 (Marshmallow / api level 23) or later
  begin
    LView := GetWindowDecorView;
    if Assigned(LView) then
    begin
      LWindowInsets := LView.getRootWindowInsets;
      if Assigned(LWindowInsets) then
      begin
        if TOSVersion.Check(11) then // Android 11 (api level 30) or later
        begin
          LWindowInsetsAndroid11 := TAndroid11.TJWindowInsets.Wrap(TAndroidHelper.JObjectToID(LWindowInsets));
          if Assigned(LWindowInsetsAndroid11) then
          begin
            LInsets := LWindowInsetsAndroid11.getInsets(TAndroid11.TJWindowInsets_Type.JavaClass.mandatorySystemGestures);
            if Assigned(LInsets) then
              Result := TRect.Create(LInsets.left, LInsets.top, LInsets.right, LInsets.bottom);
            LInsets := LWindowInsetsAndroid11.getInsets(TAndroid11.TJWindowInsets_Type.JavaClass.systemBars);
            if Assigned(LInsets) then
              Result := TRect.Create(Max(Result.Left, LInsets.left), Max(Result.Top, LInsets.top),
                Max(Result.Right, LInsets.right), Max(Result.Bottom, LInsets.bottom));
          end;
        end
        else
        begin
          if TOSVersion.Check(10) then // Android 10 (api level 29)
          begin
            LInsets := TAndroid10.TJWindowInsets.Wrap(TAndroidHelper.JObjectToID(LWindowInsets)).getMandatorySystemGestureInsets;
            if Assigned(LInsets) then
              Result := TRect.Create(LInsets.left, LInsets.top, LInsets.right, LInsets.bottom);
          end;
          Result := TRect.Create(Max(Result.Left, LWindowInsets.getSystemWindowInsetLeft),
            Max(Result.Top, LWindowInsets.getSystemWindowInsetTop),
            Max(Result.Right, LWindowInsets.getSystemWindowInsetRight),
            Max(Result.Bottom, LWindowInsets.getSystemWindowInsetBottom));
        end;
      end;
    end;
  end
  {$IF CompilerVersion < 34.0} // Delphi Sydney 10.4
  else if TOSVersion.Check(4, 4) then // Android 4.4 (Kitkat / api level 19) to Android 5.1 (Lollipop MR1 / api level 22)
    Result := TAndroidBeforeMarshmallow.AbsoluteSystemInsets;
  {$IFEND}
end;

function TSystemBarsInsetsCalculator.DoGetAbsoluteTappableInsets(const AForm: TCommonCustomForm): TRect;
var
  LView: JView;
  LWindowInsets: JWindowInsets;
  LInsets: TAndroid10.JInsets;
begin
  Result := TRect.Empty;
  if TOSVersion.Check(10) then // Android 10 (api level 29) or later
  begin
    LView := GetWindowDecorView;
    if Assigned(LView) then
    begin
      LWindowInsets := LView.getRootWindowInsets;
      if Assigned(LWindowInsets) then
      begin
        if TOSVersion.Check(11) then // Android 11 (api level 30) or later
          LInsets := TAndroid11.TJWindowInsets.Wrap(TAndroidHelper.JObjectToID(LWindowInsets)).getInsets(
            TAndroid11.TJWindowInsets_Type.JavaClass.tappableElement)
        else
          LInsets := TAndroid10.TJWindowInsets.Wrap(TAndroidHelper.JObjectToID(LWindowInsets)).getTappableElementInsets;
        if Assigned(LInsets) then
          Result := TRect.Create(LInsets.left, LInsets.top, LInsets.right, LInsets.bottom);
      end;
    end;
  end
  else
    Result := DoGetAbsoluteInsets(AForm);
end;

function TSystemBarsInsetsCalculator.GetAbsoluteInsets(const AForm: TCommonCustomForm): TRect;
var
  LAbsoluteTappableInsets: TRect;
begin
  Result := TRect.Empty;
  if not HasSystemBars(AForm) then
    Exit;
  case AForm.SystemBars.Visibility of
    TScreenSystemBars.TVisibilityMode.Visible: // GestureBar
      begin
        Result := DoGetAbsoluteInsets(AForm);
        LAbsoluteTappableInsets := DoGetAbsoluteTappableInsets(AForm);
        Result := TRect.Create(Max(Result.Left - LAbsoluteTappableInsets.Left, 0),
          Max(Result.Top - LAbsoluteTappableInsets.Top, 0),
          Max(Result.Right - LAbsoluteTappableInsets.Right, 0),
          Max(Result.Bottom - LAbsoluteTappableInsets.Bottom, 0));
      end;
    TScreenSystemBars.TVisibilityMode.Invisible:
      ; // None
    TScreenSystemBars.TVisibilityMode.VisibleAndOverlap:
      Result := DoGetAbsoluteInsets(AForm); // StatusBar + NavigationBar + GestureBar
  end;
end;

function TSystemBarsInsetsCalculator.GetAbsoluteTappableInsets(const AForm: TCommonCustomForm): TRect;
begin
  Result := TRect.Empty;
  if not HasSystemBars(AForm) then
    Exit;
  case AForm.SystemBars.Visibility of
    TScreenSystemBars.TVisibilityMode.Visible:
      ; // None
    TScreenSystemBars.TVisibilityMode.Invisible:
      ; // None
    TScreenSystemBars.TVisibilityMode.VisibleAndOverlap:
      Result := DoGetAbsoluteTappableInsets(AForm); // StatusBar + NavigationBar
  end;
end;

function TSystemBarsInsetsCalculator.GetInsets(const AForm: TCommonCustomForm): TRectF;

  function GetCurrentInsets(const AForm: TCommonCustomForm): TRectF;
  var
    LFormSystemBars: TScreenSystemBars;
  begin
    LFormSystemBars := AForm.SystemBars;
    if Assigned(LFormSystemBars) then
      Result := LFormSystemBars.Insets
    else
      Result := TRectF.Empty;
  end;

begin
  if not Assigned(AForm) then
    Result := TRectF.Empty
  else if (not AForm.IsHandleAllocated) or (not AForm.Active) then
    Result := GetCurrentInsets(AForm)
  else
  begin
    Result := AbsoluteRectToScreenScaled(GetAbsoluteInsets(AForm));
    Result := RemoveKeyboardOverlappedBars(Result, AForm);
  end;
end;

function TSystemBarsInsetsCalculator.GetTappableInsets(const AForm: TCommonCustomForm): TRectF;

  function GetCurrentTappableInsets(const AForm: TCommonCustomForm): TRectF;
  var
    LFormSystemBars: TScreenSystemBars;
  begin
    LFormSystemBars := AForm.SystemBars;
    if Assigned(LFormSystemBars) then
      Result := LFormSystemBars.TappableInsets
    else
      Result := TRectF.Empty;
  end;

begin
  if not Assigned(AForm) then
    Result := TRectF.Empty
  else if (not AForm.IsHandleAllocated) or (not AForm.Active) then
    Result := GetCurrentTappableInsets(AForm)
  else
  begin
    Result := AbsoluteRectToScreenScaled(GetAbsoluteTappableInsets(AForm));
    Result := RemoveKeyboardOverlappedBars(Result, AForm);
  end;
end;

function TSystemBarsInsetsCalculator.GetVirtualKeyboardBounds: TRect;
begin
  Result := FVirtualKeyboardBounds;
end;

function TSystemBarsInsetsCalculator.HasGestureNavigationBar(const AForm: TCommonCustomForm): Boolean;

  function SameRectIgnoringTop(const ALeft, ARight: TRect): Boolean;
  begin
    Result := (ALeft.Left = ARight.Left) and (ALeft.Right = ARight.Right) and
      (ALeft.Bottom = ARight.Bottom);
  end;

begin
  if TOSVersion.Check(10) then // Android 10 (api level 29) or later
    Result := HasSystemBars(AForm) and AForm.Active and not SameRectIgnoringTop(DoGetAbsoluteInsets(AForm),
      DoGetAbsoluteTappableInsets(AForm))
  else
    Result := False;
end;

function TSystemBarsInsetsCalculator.HasSystemBars(const AForm: TCommonCustomForm): Boolean;
var
  LFormSystemBars: TScreenSystemBars;
begin
  Result := False;
  if Assigned(AForm) and AForm.IsHandleAllocated then
  begin
    LFormSystemBars := AForm.SystemBars;
    if Assigned(LFormSystemBars) then
      Result := LFormSystemBars.Visibility <> TScreenSystemBars.TVisibilityMode.Invisible;
  end;
end;

function TSystemBarsInsetsCalculator.RemoveKeyboardOverlappedBars(const AInsets: TRectF; const AForm: TCommonCustomForm): TRectF;

  function IsIMEReallyVisible: Boolean;
  var
    LView: JView;
    LWindowInsets: JWindowInsets;
    LWindowInsetsAndroid11: TAndroid11.JWindowInsets;
  begin
    Result := True;
    if TOSVersion.Check(11) then // Android 11 (api level 30) or later
    begin
      LView := GetWindowDecorView;
      if Assigned(LView) then
      begin
        LWindowInsets := LView.getRootWindowInsets;
        if Assigned(LWindowInsets) then
        begin
          LWindowInsetsAndroid11 := TAndroid11.TJWindowInsets.Wrap(TAndroidHelper.JObjectToID(LWindowInsets));
          if Assigned(LWindowInsetsAndroid11) then
            Result := LWindowInsetsAndroid11.isVisible(TAndroid11.TJWindowInsets_Type.JavaClass.ime);
        end;
      end;
    end;
  end;

begin
  Result := AInsets;
  if (not FVirtualKeyboardBounds.IsEmpty) and (AInsets <> TRectF.Empty) and Assigned(AForm) and AForm.Active then
    if (FVirtualKeyboardBounds.Top <> 0) and (FVirtualKeyboardBounds.Left = 0) and // Check if virtual keyboard is in bottom
      (Result.Bottom <> Max(Result.Bottom - FVirtualKeyboardBounds.Height, 0)) and
      IsIMEReallyVisible then
    begin
      Result.Bottom := Max(Result.Bottom - FVirtualKeyboardBounds.Height, 0); // Removing bottom system bars
    end;
end;

procedure TSystemBarsInsetsCalculator.SetVirtualKeyboardBounds(const ABounds: TRect);
begin
  FVirtualKeyboardBounds := ABounds;
end;

{$ENDIF}

end.
