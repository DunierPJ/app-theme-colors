unit App.SystemBars.Android.Interfaces;

interface

{$SCOPEDENUMS ON}
{$IFDEF ANDROID}

uses
  { Delphi }
  System.SysUtils,
  System.Types,
  System.UITypes,
  FMX.Forms,
  FMX.Platform,
  App.SystemBars;

type
  { IWindowServiceFix }

  IWindowServiceFix = interface
    ['{3F2E4A91-8B32-4D90-9E1A-7F1C9902611A}']
    function GetWindowService: IFMXWindowService;
    property WindowService: IFMXWindowService read GetWindowService;
  end;

  { ISystemBarsInsetsCalculator }

  ISystemBarsInsetsCalculator = interface
    ['{A5413F70-D511-477D-B3F0-71328E14E290}']
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

  { ISystemBarsVisibilityController }

  ISystemBarsVisibilityController = interface
    ['{C158F2E2-1A79-4A9B-983C-234E45D92A02}']
    procedure SetVisibility(const AForm: TCommonCustomForm; const AMode: TScreenSystemBars.TVisibilityMode);
    procedure DoSetVisibility(const AForm: TCommonCustomForm; const AMode: TScreenSystemBars.TVisibilityMode);
    function GetFullScreen(const AForm: TCommonCustomForm): Boolean;
    procedure SetFullScreen(const AForm: TCommonCustomForm; const AValue: Boolean);
    procedure SetShowFullScreenIcon(const AForm: TCommonCustomForm; const AValue: Boolean);
    procedure TryFixInvisibleMode;
    procedure FormReleased(const AForm: TCommonCustomForm);
  end;

  { ISystemBarsColorController }

  ISystemBarsColorController = interface
    ['{981452D3-7F2A-4B60-84E1-602931D45070}']
    procedure SetStatusBarBackgroundColor(const AForm: TCommonCustomForm; const AColor: TAlphaColor);
    procedure SetNavigationBarBackgroundColor(const AForm: TCommonCustomForm; const AColor: TAlphaColor);
  end;

  { ISystemBarsEventListener }

  ISystemBarsEventListener = interface
    ['{73A1604B-9E39-44F1-8B90-951EBC2C4123}']
    procedure StartListening;
    procedure StopListening;
    procedure CheckInsetsChanges(const AForm: TCommonCustomForm);
    procedure SetChangeChecksEnabled(const AValue: Boolean);
    function GetChangeChecksEnabled: Boolean;
    property ChangeChecksEnabled: Boolean read GetChangeChecksEnabled write SetChangeChecksEnabled;
  end;

{$ELSE}
implementation
{$ENDIF}

{$IFDEF ANDROID}
implementation
{$ENDIF}

end.
