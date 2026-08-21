unit App.ThemeInterfaces;

interface

uses
  System.Classes,
  System.Messaging,
  App.ColorScheme;

type
  TThemeMode = (tmSystem, tmLight, tmDark);

  ISystemThemeDetector = interface
    ['{6B82810B-2268-450F-A165-8F3EBA928CD0}']
    function IsSystemDark: Boolean;
  end;

  ISystemBarsService = interface
    ['{20B2F2A1-03D4-49BA-B66A-7CE9FA7B92A4}']
    procedure ApplySystemBars(const AScheme: TColorScheme; const AIsDark: Boolean);
  end;

  IThemeManager = interface
    ['{A91C28D5-3E7F-4B81-995B-883316E2E109}']
    function GetMode: TThemeMode;
    procedure SetMode(const Value: TThemeMode);
    function IsDark: Boolean;
    function Scheme: TColorScheme;
    procedure SetCustomSchemes(const ALight, ADark: TColorScheme);
    procedure ApplySystemBars;
    procedure AutoSubscribe(AOwner: TComponent; const AListener: TMessageListener);

    property Mode: TThemeMode read GetMode write SetMode;
  end;

implementation

end.
