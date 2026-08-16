unit App.ColorScheme;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  System.JSON;

type
  TColorScheme = record
    Primary: TAlphaColor;
    OnPrimary: TAlphaColor;
    PrimaryContainer: TAlphaColor;
    OnPrimaryContainer: TAlphaColor;
    Secondary: TAlphaColor;
    OnSecondary: TAlphaColor;
    SecondaryContainer: TAlphaColor;
    OnSecondaryContainer: TAlphaColor;
    Tertiary: TAlphaColor;
    OnTertiary: TAlphaColor;
    TertiaryContainer: TAlphaColor;
    OnTertiaryContainer: TAlphaColor;
    Error: TAlphaColor;
    OnError: TAlphaColor;
    ErrorContainer: TAlphaColor;
    OnErrorContainer: TAlphaColor;
    Background: TAlphaColor;
    OnBackground: TAlphaColor;
    Surface: TAlphaColor;
    OnSurface: TAlphaColor;
    SurfaceVariant: TAlphaColor;
    OnSurfaceVariant: TAlphaColor;
    Outline: TAlphaColor;

    /// <summary>Carrega o esquema de cores a partir de uma string JSON.</summary>
    class function FromJSON(const AJsonString: string; const ABaseScheme: TColorScheme): TColorScheme; static;

    /// <summary>Carrega o esquema de cores a partir de um arquivo JSON.</summary>
    class function LoadFromFile(const AFileName: string; const ABaseScheme: TColorScheme): TColorScheme; static;

    /// <summary>Exporta o esquema de cores atual para formato JSON.</summary>
    function ToJSON: string;
  end;

const
  LightScheme: TColorScheme = (
    Primary: $FF0B9945;
    OnPrimary: $FFFFFFFF;
    PrimaryContainer: $FFA2E6BE;
    OnPrimaryContainer: $FF043317;
    Secondary: $FF996206;
    OnSecondary: $FFFFFFFF;
    SecondaryContainer: $FFE6CBA0;
    OnSecondaryContainer: $FF332102;
    Tertiary: $FF184099;
    OnTertiary: $FFFFFFFF;
    TertiaryContainer: $FFA9BBE6;
    OnTertiaryContainer: $FF081533;
    Error: $FF991515;
    OnError: $FFFFFFFF;
    ErrorContainer: $FFE6A7A7;
    OnErrorContainer: $FF330707;
    Background: $FFfbfcfc;
    OnBackground: $FF313332;
    Surface: $FFfbfcfc;
    OnSurface: $FF313332;
    SurfaceVariant: $FFd8e6de;
    OnSurfaceVariant: $FF53665b;
    Outline: $FF7d9988
  );

  DarkScheme: TColorScheme = (
    Primary: $FF86E6AD;
    OnPrimary: $FF054C22;
    PrimaryContainer: $FF07662E;
    OnPrimaryContainer: $FFA2E6BE;
    Secondary: $FFE6C183;
    OnSecondary: $FF4C3103;
    SecondaryContainer: $FF664104;
    OnSecondaryContainer: $FFE6CBA0;
    Tertiary: $FF8FAAE6;
    OnTertiary: $FF0C204C;
    TertiaryContainer: $FF102B66;
    OnTertiaryContainer: $FFA9BBE6;
    Error: $FFE68D8D;
    OnError: $FF4C0B0B;
    ErrorContainer: $FF660E0E;
    OnErrorContainer: $FFE6A7A7;
    Background: $FF313332;
    OnBackground: $FFe2e6e4;
    Surface: $FF313332;
    OnSurface: $FFe2e6e4;
    SurfaceVariant: $FF53665b;
    OnSurfaceVariant: $FFd2e6da;
    Outline: $FF9eb3a6
  );

implementation

function ParseColor(const S: string; DefaultColor: TAlphaColor): TAlphaColor;
var
  CleanS: string;
  Val64: Int64;
begin
  CleanS := S.Trim;
  if CleanS.IsEmpty then
    Exit(DefaultColor);

  if CleanS.StartsWith('#') then
  begin
    CleanS := CleanS.Substring(1);
    if Length(CleanS) = 6 then
      CleanS := 'FF' + CleanS;
    CleanS := '$' + CleanS;
  end;

  if TryStrToInt64(CleanS, Val64) then
    Result := TAlphaColor(Val64)
  else
    Result := DefaultColor;
end;

class function TColorScheme.FromJSON(const AJsonString: string; const ABaseScheme: TColorScheme): TColorScheme;
var
  JsonObj: TJSONObject;

  function GetColor(const Key: string; DefaultColor: TAlphaColor): TAlphaColor;
  var
    Val: TJSONValue;
  begin
    Result := DefaultColor;
    if JsonObj <> nil then
    begin
      Val := JsonObj.GetValue(Key);
      if Val <> nil then
        Result := ParseColor(Val.Value, DefaultColor);
    end;
  end;

begin
  Result := ABaseScheme;
  if AJsonString.Trim.IsEmpty then
    Exit;

  JsonObj := TJSONObject.ParseJSONValue(AJsonString) as TJSONObject;
  if JsonObj = nil then
    Exit;

  try
    Result.Primary            := GetColor('Primary', ABaseScheme.Primary);
    Result.OnPrimary          := GetColor('OnPrimary', ABaseScheme.OnPrimary);
    Result.PrimaryContainer   := GetColor('PrimaryContainer', ABaseScheme.PrimaryContainer);
    Result.OnPrimaryContainer := GetColor('OnPrimaryContainer', ABaseScheme.OnPrimaryContainer);
    Result.Secondary          := GetColor('Secondary', ABaseScheme.Secondary);
    Result.OnSecondary        := GetColor('OnSecondary', ABaseScheme.OnSecondary);
    Result.SecondaryContainer := GetColor('SecondaryContainer', ABaseScheme.SecondaryContainer);
    Result.OnSecondaryContainer := GetColor('OnSecondaryContainer', ABaseScheme.OnSecondaryContainer);
    Result.Tertiary           := GetColor('Tertiary', ABaseScheme.Tertiary);
    Result.OnTertiary         := GetColor('OnTertiary', ABaseScheme.OnTertiary);
    Result.TertiaryContainer  := GetColor('TertiaryContainer', ABaseScheme.TertiaryContainer);
    Result.OnTertiaryContainer := GetColor('OnTertiaryContainer', ABaseScheme.OnTertiaryContainer);
    Result.Error              := GetColor('Error', ABaseScheme.Error);
    Result.OnError            := GetColor('OnError', ABaseScheme.OnError);
    Result.ErrorContainer     := GetColor('ErrorContainer', ABaseScheme.ErrorContainer);
    Result.OnErrorContainer   := GetColor('OnErrorContainer', ABaseScheme.OnErrorContainer);
    Result.Background         := GetColor('Background', ABaseScheme.Background);
    Result.OnBackground       := GetColor('OnBackground', ABaseScheme.OnBackground);
    Result.Surface            := GetColor('Surface', ABaseScheme.Surface);
    Result.OnSurface          := GetColor('OnSurface', ABaseScheme.OnSurface);
    Result.SurfaceVariant     := GetColor('SurfaceVariant', ABaseScheme.SurfaceVariant);
    Result.OnSurfaceVariant   := GetColor('OnSurfaceVariant', ABaseScheme.OnSurfaceVariant);
    Result.Outline            := GetColor('Outline', ABaseScheme.Outline);
  finally
    JsonObj.Free;
  end;
end;

class function TColorScheme.LoadFromFile(const AFileName: string; const ABaseScheme: TColorScheme): TColorScheme;
var
  SL: TStringList;
begin
  Result := ABaseScheme;
  if not FileExists(AFileName) then
    Exit;

  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFileName, TEncoding.UTF8);
    Result := FromJSON(SL.Text, ABaseScheme);
  finally
    SL.Free;
  end;
end;

function TColorScheme.ToJSON: string;
var
  JsonObj: TJSONObject;
begin
  JsonObj := TJSONObject.Create;
  try
    JsonObj.AddPair('Primary', '$' + IntToHex(Primary, 8));
    JsonObj.AddPair('OnPrimary', '$' + IntToHex(OnPrimary, 8));
    JsonObj.AddPair('PrimaryContainer', '$' + IntToHex(PrimaryContainer, 8));
    JsonObj.AddPair('OnPrimaryContainer', '$' + IntToHex(OnPrimaryContainer, 8));
    JsonObj.AddPair('Secondary', '$' + IntToHex(Secondary, 8));
    JsonObj.AddPair('OnSecondary', '$' + IntToHex(OnSecondary, 8));
    JsonObj.AddPair('SecondaryContainer', '$' + IntToHex(SecondaryContainer, 8));
    JsonObj.AddPair('OnSecondaryContainer', '$' + IntToHex(OnSecondaryContainer, 8));
    JsonObj.AddPair('Tertiary', '$' + IntToHex(Tertiary, 8));
    JsonObj.AddPair('OnTertiary', '$' + IntToHex(OnTertiary, 8));
    JsonObj.AddPair('TertiaryContainer', '$' + IntToHex(TertiaryContainer, 8));
    JsonObj.AddPair('OnTertiaryContainer', '$' + IntToHex(OnTertiaryContainer, 8));
    JsonObj.AddPair('Error', '$' + IntToHex(Error, 8));
    JsonObj.AddPair('OnError', '$' + IntToHex(OnError, 8));
    JsonObj.AddPair('ErrorContainer', '$' + IntToHex(ErrorContainer, 8));
    JsonObj.AddPair('OnErrorContainer', '$' + IntToHex(OnErrorContainer, 8));
    JsonObj.AddPair('Background', '$' + IntToHex(Background, 8));
    JsonObj.AddPair('OnBackground', '$' + IntToHex(OnBackground, 8));
    JsonObj.AddPair('Surface', '$' + IntToHex(Surface, 8));
    JsonObj.AddPair('OnSurface', '$' + IntToHex(OnSurface, 8));
    JsonObj.AddPair('SurfaceVariant', '$' + IntToHex(SurfaceVariant, 8));
    JsonObj.AddPair('OnSurfaceVariant', '$' + IntToHex(OnSurfaceVariant, 8));
    JsonObj.AddPair('Outline', '$' + IntToHex(Outline, 8));
    Result := JsonObj.Format(2);
  finally
    JsonObj.Free;
  end;
end;

end.

