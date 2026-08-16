unit App.ThemeApplier;

interface

uses
  System.Classes, 
  System.SysUtils, 
  System.Rtti,
  System.UITypes,
  FMX.Types, 
  FMX.Objects, 
  FMX.Text,
  FMX.Graphics,
  App.ColorScheme, 
  App.ThemeManager, 
  App.BitmapColor;

type
  TThemeApplier = class
  private
    class function ColorByName(const Scheme: TColorScheme; const AName: string;
      out AColor: TAlphaColor): Boolean; static;
    class procedure SetSkiaPropColor(AObject: TFmxObject; const AColor: TAlphaColor;
      const PropNames: array of string); static;
    class procedure ApplyTag(AObject: TFmxObject; const Scheme: TColorScheme); static;
  public
    class procedure ApplyToTree(ARoot: TFmxObject); static;
  end;

implementation

class function TThemeApplier.ColorByName(const Scheme: TColorScheme;
  const AName: string; out AColor: TAlphaColor): Boolean;
var
  N: string;
begin
  Result := True;
  N := AName.Trim;

       if SameText(N, 'Primary') then AColor := Scheme.Primary
  else if SameText(N, 'OnPrimary') then AColor := Scheme.OnPrimary
  else if SameText(N, 'PrimaryContainer') then AColor := Scheme.PrimaryContainer
  else if SameText(N, 'OnPrimaryContainer') then AColor := Scheme.OnPrimaryContainer
  else if SameText(N, 'Secondary') then AColor := Scheme.Secondary
  else if SameText(N, 'OnSecondary') then AColor := Scheme.OnSecondary
  else if SameText(N, 'SecondaryContainer') then AColor := Scheme.SecondaryContainer
  else if SameText(N, 'OnSecondaryContainer') then AColor := Scheme.OnSecondaryContainer
  else if SameText(N, 'Tertiary') then AColor := Scheme.Tertiary
  else if SameText(N, 'OnTertiary') then AColor := Scheme.OnTertiary
  else if SameText(N, 'TertiaryContainer') then AColor := Scheme.TertiaryContainer
  else if SameText(N, 'OnTertiaryContainer') then AColor := Scheme.OnTertiaryContainer
  else if SameText(N, 'Error') then AColor := Scheme.Error
  else if SameText(N, 'OnError') then AColor := Scheme.OnError
  else if SameText(N, 'ErrorContainer') then AColor := Scheme.ErrorContainer
  else if SameText(N, 'OnErrorContainer') then AColor := Scheme.OnErrorContainer
  else if SameText(N, 'Background') then AColor := Scheme.Background
  else if SameText(N, 'OnBackground') then AColor := Scheme.OnBackground
  else if SameText(N, 'Surface') then AColor := Scheme.Surface
  else if SameText(N, 'OnSurface') then AColor := Scheme.OnSurface
  else if SameText(N, 'SurfaceVariant') then AColor := Scheme.SurfaceVariant
  else if SameText(N, 'OnSurfaceVariant') then AColor := Scheme.OnSurfaceVariant
  else if SameText(N, 'Outline') then AColor := Scheme.Outline
  else Result := False;
end;

class procedure TThemeApplier.SetSkiaPropColor(AObject: TFmxObject; const AColor: TAlphaColor;
  const PropNames: array of string);
var
  Ctx: TRttiContext;
  Typ: TRttiType;
  Prop: TRttiProperty;
  PropName: string;
begin
  Ctx := TRttiContext.Create;
  try
    Typ := Ctx.GetType(AObject.ClassType);
    if Typ = nil then Exit;

    for PropName in PropNames do
    begin
      Prop := Typ.GetProperty(PropName);
      if (Prop <> nil) and Prop.IsWritable then
      begin
        Prop.SetValue(AObject, TValue.From<TAlphaColor>(AColor));
        Exit;
      end;
    end;
  finally
    Ctx.Free;
  end;
end;

class procedure TThemeApplier.ApplyTag(AObject: TFmxObject; const Scheme: TColorScheme);
var
  Instructions, Parts: TArray<string>;
  Instruction, Kind, RoleName, ClsName: string;
  Cor: TAlphaColor;
begin
  if (AObject = nil) or AObject.TagString.IsEmpty then
    Exit;

  Instructions := AObject.TagString.Split([';']);
  for Instruction in Instructions do
  begin
    Parts := Instruction.Trim.Split([':']);
    if Length(Parts) <> 2 then
      Continue;

    Kind := Parts[0].Trim;
    RoleName := Parts[1].Trim;

    if not ColorByName(Scheme, RoleName, Cor) then
      Continue;

    ClsName := AObject.ClassName;

    if SameText(Kind, 'Fill') and (AObject is TShape) then
      TShape(AObject).Fill.Color := Cor

    else if SameText(Kind, 'Stroke') and (AObject is TShape) then
      TShape(AObject).Stroke.Color := Cor

    else if SameText(Kind, 'Font') and (AObject is TText) then
      TText(AObject).Color := Cor

    else if SameText(Kind, 'Bitmap') and (AObject is TImage) then
    begin
      if (TImage(AObject).Bitmap <> nil) and not TImage(AObject).Bitmap.IsEmpty then
        TImage(AObject).Bitmap.ReplaceOpaqueColor(Cor);
    end

    // --- Suporte Nativo a Componentes Skia FMX ---
    else if SameText(ClsName, 'TSkLabel') then
    begin
      if SameText(Kind, 'Font') or SameText(Kind, 'Fill') then
        SetSkiaPropColor(AObject, Cor, ['TextSettings.FontColor', 'Words.FontColor', 'Color']);
    end

    else if SameText(ClsName, 'TSkSvg') then
    begin
      if SameText(Kind, 'Fill') or SameText(Kind, 'Bitmap') or SameText(Kind, 'Stroke') then
        SetSkiaPropColor(AObject, Cor, ['Svg.OverrideColor', 'OverrideColor', 'Color']);
    end

    else if SameText(ClsName, 'TSkAnimatedImage') then
    begin
      if SameText(Kind, 'Bitmap') or SameText(Kind, 'Fill') then
        SetSkiaPropColor(AObject, Cor, ['Color']);
    end;
  end;
end;

class procedure TThemeApplier.ApplyToTree(ARoot: TFmxObject);
var
  I: Integer;
begin
  if ARoot = nil then
    Exit;

  ApplyTag(ARoot, TThemeManager.Scheme);
  for I := 0 to ARoot.ChildrenCount - 1 do
    ApplyToTree(ARoot.Children[I]);
end;

end.