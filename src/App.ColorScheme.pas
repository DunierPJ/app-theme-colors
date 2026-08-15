unit App.ColorScheme;

interface

uses
  System.UITypes;

type
  TColorScheme = record
	Primary,
	OnPrimary,
	PrimaryContainer,
	OnPrimaryContainer,
	Secondary,
	OnSecondary,
	SecondaryContainer,
	OnSecondaryContainer,
	Tertiary,
	OnTertiary,
	TertiaryContainer,
	OnTertiaryContainer,
	Error,
	OnError,
	ErrorContainer,
	OnErrorContainer,
	Background,
	OnBackground,
	Surface,
	OnSurface,
	SurfaceVariant,
	OnSurfaceVariant,
	Outline;
  end;

const
  LightScheme: TColorScheme = (
    Primary: #FF0B9945;
    OnPrimary: #FFFFFFFF;
    PrimaryContainer: #FFA2E6BE;
    OnPrimaryContainer: #FF043317;
    Secondary: #FF996206;
    OnSecondary: #FFFFFFFF;
    SecondaryContainer: #FFE6CBA0;
    OnSecondaryContainer: #FF332102;
    Tertiary: #FF184099;
    OnTertiary: #FFFFFFFF;
    TertiaryContainer: #FFA9BBE6;
    OnTertiaryContainer: #FF081533;
    Error: #FF991515;
    OnError: #FFFFFFFF;
    ErrorContainer: #FFE6A7A7;
    OnErrorContainer: #FF330707;
    Background: #FFfbfcfc;
    OnBackground: #FF313332;
    Surface: #FFfbfcfc;
    OnSurface: #FF313332;
    SurfaceVariant: #FFd8e6de;
    OnSurfaceVariant: #FF53665b;
    Outline: #FF7d9988;
  );

  DarkScheme: TColorScheme = (
    Primary: #FF86E6AD;
    OnPrimary: #FF054C22;
    PrimaryContainer: #FF07662E;
    OnPrimaryContainer: #FFA2E6BE;
    Secondary: #FFE6C183;
    OnSecondary: #FF4C3103;
    SecondaryContainer: #FF664104;
    OnSecondaryContainer: #FFE6CBA0;
    Tertiary: #FF8FAAE6;
    OnTertiary: #FF0C204C;
    TertiaryContainer: #FF102B66;
    OnTertiaryContainer: #FFA9BBE6;
    Error: #FFE68D8D;
    OnError: #FF4C0B0B;
    ErrorContainer: #FF660E0E;
    OnErrorContainer: #FFE6A7A7;
    Background: #FF313332;
    OnBackground: #FFe2e6e4;
    Surface: #FF313332;
    OnSurface: #FFe2e6e4;
    SurfaceVariant: #FF53665b;
    OnSurfaceVariant: #FFd2e6da;
    Outline: #FF9eb3a6;
  );

implementation

end.