unit App.SystemBars.Android.Types;

interface

{$SCOPEDENUMS ON}

{$IFDEF ANDROID}
uses
  { Delphi }
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Math,
  System.Math.Vectors,
  FMX.Types,
  FMX.Platform,
  Androidapi.JNIBridge,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers,
  Androidapi.Jni,
  Androidapi.JNI.Embarcadero,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Os,
  Androidapi.JNI.App,
  Androidapi.JNI.Widget;

type
  { TAndroid9 }

  TAndroid9 = class
  public
    type
    { WindowManager.LayoutParams }

      JWindowManager_LayoutParamsClass = interface(Androidapi.JNI.GraphicsContentViewText.JWindowManager_LayoutParamsClass)
        ['{D657960B-0CEA-4A56-9FC1-EB165CCB4891}']
      {class}
        function _GetLAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT: Integer; cdecl;
      {class}
        function _GetLAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES: Integer; cdecl;
      {class}
        property LAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT: Integer read _GetLAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT;
      {class}
        property LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES: Integer read _GetLAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
      end;

      [JavaSignature('android/view/WindowManager$LayoutParams')]
      JWindowManager_LayoutParams = interface(Androidapi.JNI.GraphicsContentViewText.JWindowManager_LayoutParams)
        ['{C849F24F-5CAC-425E-B5B0-0EE72E71966B}']
        function _GetlayoutInDisplayCutoutMode: Integer; cdecl;
        procedure _SetlayoutInDisplayCutoutMode(Value: Integer); cdecl;
        property layoutInDisplayCutoutMode: Integer read _GetlayoutInDisplayCutoutMode write _SetlayoutInDisplayCutoutMode;
      end;

      TJWindowManager_LayoutParams = class(TJavaGenericImport<TAndroid9.JWindowManager_LayoutParamsClass, TAndroid9.JWindowManager_LayoutParams>)
      end;
  end;

  { TAndroid10 }

  TAndroid10 = class
  public
    type
    { Insets }

      JInsetsClass = interface(JObjectClass)
        ['{BDB53B96-47AA-4A43-A08F-7648EE48A7D9}']
      end;

      [JavaSignature('android/graphics/Insets')]
      JInsets = interface(JObject)
        ['{A0703F81-D34D-4D59-8D3F-5E1D7DD3192D}']
        function _Getbottom: Integer; cdecl;
        function _Getleft: Integer; cdecl;
        function _Getright: Integer; cdecl;
        function _Gettop: Integer; cdecl;
        property bottom: Integer read _Getbottom;
        property left: Integer read _Getleft;
        property right: Integer read _Getright;
        property top: Integer read _Gettop;
      end;

      TJInsets = class(TJavaGenericImport<TAndroid10.JInsetsClass, TAndroid10.JInsets>)
      end;

    { WindowInsets }

      JWindowInsetsClass = interface(Androidapi.JNI.GraphicsContentViewText.JWindowInsetsClass)
        ['{6BCCFCCA-A7F0-4740-B4D6-D03286DAD89C}']
      end;

      [JavaSignature('android/view/WindowInsets')]
      JWindowInsets = interface(Androidapi.JNI.GraphicsContentViewText.JWindowInsets)
        ['{05AFC51B-3683-4DD1-BB1A-22799899142B}']
        function getMandatorySystemGestureInsets: JInsets; cdecl;
        function getTappableElementInsets: JInsets; cdecl;
      end;

      TJWindowInsets = class(TJavaGenericImport<TAndroid10.JWindowInsetsClass, TAndroid10.JWindowInsets>)
      end;

    { Window }

      JWindowClass = interface(Androidapi.JNI.GraphicsContentViewText.JWindowClass)
        ['{FE27644B-35A7-48EA-90A3-42CC8CB5E1B9}']
      end;

      [JavaSignature('android/view/Window')]
      JWindow = interface(Androidapi.JNI.GraphicsContentViewText.JWindow)
        ['{25E670D9-5AFB-4C61-9703-D5E5CD89F66F}']
        procedure setNavigationBarContrastEnforced(enforceContrast: Boolean); cdecl;
        procedure setStatusBarContrastEnforced(enforceContrast: Boolean); cdecl;
      end;

      TJWindow = class(TJavaGenericImport<TAndroid10.JWindowClass, TAndroid10.JWindow>)
      end;
  end;

  { TAndroid11 }

  TAndroid11 = class
  public
    type
    { WindowInsets.Type }

      JWindowInsets_TypeClass = interface(JObjectClass)
        ['{847139A7-6187-4D24-86FE-44BB6017F246}']
      {class}
        function captionBar: Integer; cdecl;
      {class}
        function displayCutout: Integer; cdecl;
      {class}
        function ime: Integer; cdecl;
      {class}
        function mandatorySystemGestures: Integer; cdecl;
      {class}
        function navigationBars: Integer; cdecl;
      {class}
        function statusBars: Integer; cdecl;
      {class}
        function systemBars: Integer; cdecl;
      {class}
        function systemGestures: Integer; cdecl;
      {class}
        function tappableElement: Integer; cdecl;
      end;

      [JavaSignature('android/view/WindowInsets$Type')]
      JWindowInsets_Type = interface(JObject)
        ['{380D2B14-3C81-4F30-888E-1465CF5D2BCF}']
      end;

      TJWindowInsets_Type = class(TJavaGenericImport<TAndroid11.JWindowInsets_TypeClass, TAndroid11.JWindowInsets_Type>)
      end;

    { WindowInsetsController }

      JWindowInsetsControllerClass = interface(JObjectClass)
        ['{D7FCB1D1-65AD-4A41-B873-6F8CD3B1E6F4}']
      {class}
        function _GetAPPEARANCE_LIGHT_NAVIGATION_BARS: Integer; cdecl;
      {class}
        function _GetAPPEARANCE_LIGHT_STATUS_BARS: Integer; cdecl;
      {class}
        function _GetBEHAVIOR_SHOW_BARS_BY_SWIPE: Integer; cdecl;
      {class}
        function _GetBEHAVIOR_SHOW_BARS_BY_TOUCH: Integer; cdecl;
      {class}
        function _GetBEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE: Integer; cdecl;
      {class}
        property APPEARANCE_LIGHT_NAVIGATION_BARS: Integer read _GetAPPEARANCE_LIGHT_NAVIGATION_BARS;
      {class}
        property APPEARANCE_LIGHT_STATUS_BARS: Integer read _GetAPPEARANCE_LIGHT_STATUS_BARS;
      {class}
        property BEHAVIOR_SHOW_BARS_BY_SWIPE: Integer read _GetBEHAVIOR_SHOW_BARS_BY_SWIPE;
      {class}
        property BEHAVIOR_SHOW_BARS_BY_TOUCH: Integer read _GetBEHAVIOR_SHOW_BARS_BY_TOUCH;
      {class}
        property BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE: Integer read _GetBEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE;
      end;

      [JavaSignature('android/view/WindowInsetsController')]
      JWindowInsetsController = interface(JObject)
        ['{895DBAB1-0A52-4240-AC13-ED40474E6850}']
        function getSystemBarsAppearance: Integer; cdecl;
        function getSystemBarsBehavior: Integer; cdecl;
        procedure hide(types: Integer); cdecl;
        procedure setSystemBarsAppearance(appearance, mask: Integer); cdecl;
        procedure setSystemBarsBehavior(behavior: Integer); cdecl;
        procedure show(types: Integer); cdecl;
      end;

      TJWindowInsetsController = class(TJavaGenericImport<TAndroid11.JWindowInsetsControllerClass, TAndroid11.JWindowInsetsController>)
      end;

    { WindowInsets }

      JWindowInsetsClass = interface(Androidapi.JNI.GraphicsContentViewText.JWindowInsetsClass)
        ['{6BCCFCCA-A7F0-4740-B4D6-D03286DAD89C}']
      end;

      [JavaSignature('android/view/WindowInsets')]
      JWindowInsets = interface(Androidapi.JNI.GraphicsContentViewText.JWindowInsets)
        ['{05AFC51B-3683-4DD1-BB1A-22799899142B}']
        function getInsets(typeMask: Integer): TAndroid10.JInsets; cdecl;
        function isVisible(typeMask: Integer): Boolean; cdecl;
      end;

      TJWindowInsets = class(TJavaGenericImport<TAndroid11.JWindowInsetsClass, TAndroid11.JWindowInsets>)
      end;

    { Window }

      JWindowClass = interface(Androidapi.JNI.GraphicsContentViewText.JWindowClass)
        ['{6A055684-AA34-432C-8B18-12B7D721C599}']
      end;

      [JavaSignature('android/view/Window')]
      JWindow = interface(Androidapi.JNI.GraphicsContentViewText.JWindow)
        ['{BC863876-71E3-4292-8B2C-860FADB8066C}']
        procedure setDecorFitsSystemWindows(decorFitsSystemWindows: Boolean); cdecl;
      end;

      TJWindowEx = class(TJavaGenericImport<TAndroid11.JWindowClass, TAndroid11.JWindow>)
      end;

    { View }

      JViewClass = interface(Androidapi.JNI.GraphicsContentViewText.JViewClass)
        ['{44C48716-DA19-42A7-9141-E137DC92598F}']
      end;

      [JavaSignature('android/view/View')]
      JView = interface(Androidapi.JNI.GraphicsContentViewText.JView)
        ['{150FC57B-6421-4F25-A626-D0B51AA9E4FF}']
        function getWindowInsetsController: JWindowInsetsController; cdecl;
      end;

      TJView = class(TJavaGenericImport<TAndroid11.JViewClass, TAndroid11.JView>)
      end;
  end;

{$REGION 'Backwards compatibility'}
{$IF CompilerVersion < 34.0} // Delphi Sydney 10.4
  { TAndroidBeforeMarshmallow }

  TAndroidBeforeMarshmallow = class
  strict private
    class function GetAbsoluteNavigationBarInsets: TRect; static;
    class function GetAbsoluteStatusBarHeight: Integer; static;
  public
    class function AbsoluteSystemInsets: TRect; static;
  end;
{$IFEND}
{$ENDREGION}

{ Helper functions }
function GetMainActivityContentView: JViewGroup;
function GetWindowDecorView: JView;
function AbsoluteRectToScreenScaled(const AAbsoluteRect: TRect): TRectF;
function IsDarkTheme: Boolean;

{$ENDIF}

implementation

{$IFDEF ANDROID}

{$REGION 'Backwards compatibility'}
{$IF CompilerVersion < 34.0} // Delphi Sydney 10.4
{ TAndroidBeforeMarshmallow }

class function TAndroidBeforeMarshmallow.GetAbsoluteNavigationBarInsets: TRect;

  function IsTablet: Boolean;
  begin
    Result := (TAndroidHelper.Context.getResources().getConfiguration().screenLayout and
      TJConfiguration.JavaClass.SCREENLAYOUT_SIZE_MASK) >= TJConfiguration.JavaClass.SCREENLAYOUT_SIZE_LARGE;
  end;

type
  TNavigationBarLocation = (Right, Bottom);
var
  LResources: JResources;
  LNavigationBarExists: Boolean;
  LOrientation: Integer;
  LResourceID: Integer;
  LLocation: TNavigationBarLocation;
begin
  Result := TRect.Empty;
  try
    LLocation := TNavigationBarLocation.Bottom;
    LResources := TAndroidHelper.Context.getResources();
    try
      LResourceID := LResources.getIdentifier(TAndroidHelper.StringToJString('config_showNavigationBar'), TAndroidHelper.StringToJString
        ('bool'), TAndroidHelper.StringToJString('android'));
      LNavigationBarExists := (LResourceID > 0) and LResources.getBoolean(LResourceID);
    except
      LNavigationBarExists := False;
    end;
    if LNavigationBarExists then
    begin
      LOrientation := LResources.getConfiguration().orientation;
      if IsTablet then
      begin
        if LOrientation = TJConfiguration.JavaClass.ORIENTATION_PORTRAIT then
          LResourceID := LResources.getIdentifier(TAndroidHelper.StringToJString('navigation_bar_height'), TAndroidHelper.StringToJString
            ('dimen'), TAndroidHelper.StringToJString('android'))
        else
          LResourceID := LResources.getIdentifier(TAndroidHelper.StringToJString('navigation_bar_height_landscape'),
            TAndroidHelper.StringToJString('dimen'), TAndroidHelper.StringToJString('android'));
      end
      else
      begin
        if LOrientation = TJConfiguration.JavaClass.ORIENTATION_PORTRAIT then
          LResourceID := LResources.getIdentifier(TAndroidHelper.StringToJString('navigation_bar_height'), TAndroidHelper.StringToJString
            ('dimen'), TAndroidHelper.StringToJString('android'))
        else
        begin
          LResourceID := LResources.getIdentifier(TAndroidHelper.StringToJString('navigation_bar_width'), TAndroidHelper.StringToJString
            ('dimen'), TAndroidHelper.StringToJString('android'));
          LLocation := TNavigationBarLocation.Right;
        end;
      end;
      if LResourceID > 0 then
      begin
        case LLocation of
          TNavigationBarLocation.Right:
            Result.Right := LResources.getDimensionPixelSize(LResourceID);
          TNavigationBarLocation.Bottom:
            Result.Bottom := LResources.getDimensionPixelSize(LResourceID);
        end;
      end;
    end;
  except
    Result := TRect.Empty;
  end;
end;

class function TAndroidBeforeMarshmallow.GetAbsoluteStatusBarHeight: Integer;
var
  resourceID: Integer;
  sAbis: string;
  arrAbis: TJavaObjectArray<JString>;
  I: Integer;
  needCheckStatusBarHeight: boolean;
begin
  Result := 0;
  if TOSVersion.Major >= 5 then
  begin
    sAbis := '';
    arrAbis := TJBuild.JavaClass.SUPPORTED_ABIS;
    for I := 0 to arrAbis.Length - 1 do
      sAbis := sAbis + ',' + JStringToString(arrAbis.Items[I]);
    sAbis := sAbis.trim([',']);
  end
  else
    sAbis := JStringToString(TJBuild.JavaClass.CPU_ABI) + ',' + JStringToString(TJBuild.JavaClass.CPU_ABI2);

  needCheckStatusBarHeight := (sAbis.Contains('x86') or JStringToString(TJBuild.JavaClass.FINGERPRINT).Contains('intel')
    or sAbis.Contains('arm64-v8a')) and (TOSVersion.Major >= 4);

  if (TOSVersion.Major >= 5) or (needCheckStatusBarHeight) then
  begin
    resourceID := TAndroidHelper.Activity.getResources.getIdentifier(StringToJString('status_bar_height'),
      StringToJString('dimen'), StringToJString('android'));
    if resourceID > 0 then
      Result := TAndroidHelper.Activity.getResources.getDimensionPixelSize(resourceID);
  end;
end;

class function TAndroidBeforeMarshmallow.AbsoluteSystemInsets: TRect;
begin
  Result := GetAbsoluteNavigationBarInsets;
  Result.Top := GetAbsoluteStatusBarHeight;
end;
{$IFEND}
{$ENDREGION}

function GetMainActivityContentView: JViewGroup;
var
  LMainActivity: JFMXNativeActivity;
begin
  LMainActivity := MainActivity;
  if LMainActivity <> nil then
  begin
    {$IF CompilerVersion >= 34.0} // Delphi Sydney 10.4
    Result := LMainActivity.getContentView;
    {$ELSE}
    Result := LMainActivity.getViewGroup;
    {$IFEND}
  end
  else
    Result := nil;
end;

function GetWindowDecorView: JView;
var
  LActivity: JActivity;
  LWindow: JWindow;
begin
  Result := nil;
  LActivity := TAndroidHelper.Activity;
  if Assigned(LActivity) then
  begin
    LWindow := LActivity.getWindow;
    if Assigned(LWindow) then
      Result := LWindow.getDecorView;
  end;
end;

function AbsoluteRectToScreenScaled(const AAbsoluteRect: TRect): TRectF;
var
  LEpsilonPositionRange: Integer;
begin
  if AAbsoluteRect = TRect.Empty then
    Exit(TRectF.Empty);
  Result := TRectF.Create(ConvertPixelToPoint(AAbsoluteRect.TopLeft), ConvertPixelToPoint(AAbsoluteRect.BottomRight));
  // Round to position epsilon
  LEpsilonPositionRange := -3;
  Assert(LEpsilonPositionRange = Round(Log10(TEpsilon.Position)));
  Result := TRectF.Create(RoundTo(Result.Left, LEpsilonPositionRange),
    RoundTo(Result.Top, LEpsilonPositionRange),
    RoundTo(Result.Right, LEpsilonPositionRange),
    RoundTo(Result.Bottom, LEpsilonPositionRange));
end;

function IsDarkTheme: Boolean;
{$IF CompilerVersion >= 34.0} // Delphi Sydney 10.4
var
  LSystemAppearanceService: IFMXSystemAppearanceService;
{$IFEND}
begin
  {$IF CompilerVersion >= 34.0}
  if TPlatformServices.Current.SupportsPlatformService(IFMXSystemAppearanceService, LSystemAppearanceService) then
    Result := LSystemAppearanceService.ThemeKind = TSystemThemeKind.Dark
  else
    Result := False;
  {$ELSE}
  Result := False;
  {$IFEND}
end;

initialization
  TRegTypes.RegisterType('App.SystemBars.Android.Types.TAndroid10.JInsets', TypeInfo(TAndroid10.JInsets));
  TRegTypes.RegisterType('App.SystemBars.Android.Types.TAndroid11.JWindowInsetsController', TypeInfo(TAndroid11.JWindowInsetsController));

{$ENDIF}

end.
