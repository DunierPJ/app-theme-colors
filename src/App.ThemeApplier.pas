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
  App.ColorScheme, 
  App.ThemeManager, 
  App.BitmapColor;

type
  TThemeApplier = class
  private
    class var FDominantCache: TDictionary<TBitmap, TAlphaColor>;
    class function ColorByName(const Scheme: TColorScheme; const AName: string;
      out AColor: TAlphaColor): Boolean;
    class procedure ApplyTag(AObject: TFmxObject; const Scheme: TColorScheme);
   
  public
    class constructor TThemeApplier.Create;
    class destructor TThemeApplier.Destroy;
    class procedure ApplyToTree(ARoot: TFmxObject);
  end;

implementation

class constructor TThemeApplier.Create;
begin
  FDominantCache := TDictionary<TBitmap, TAlphaColor>.Create;
end;

class destructor TThemeApplier.Destroy;
begin
  FDominantCache.Free;
end;

class function TThemeApplier.ColorByName(const Scheme: TColorScheme;
  const AName: string; out AColor: TAlphaColor): Boolean;
var
  Ctx: TRttiContext;
  Field: TRttiField;
begin
  Result := False;
  Ctx := TRttiContext.Create;
  try
    Field := Ctx.GetType(TypeInfo(TColorScheme)).GetField(AName);
    if Assigned(Field) then
    begin
      AColor := TAlphaColor(Field.GetValue(@Scheme).AsCardinal);
      Result := True;
    end;
  finally
    Ctx.Free;
  end;
end;

class procedure TThemeApplier.ApplyTag(AObject: TFmxObject; const Scheme: TColorScheme);
var
  Parts: TArray<string>;
  Kind, RoleName: string;
  Cor, Origem: TAlphaColor;
begin
  if AObject.TagString.IsEmpty then
    Exit;

  Parts := AObject.TagString.Split([':']);
  if Length(Parts) <> 2 then
    Exit;

  Kind := Parts[0].Trim;
  RoleName := Parts[1].Trim;

  if not ColorByName(Scheme, RoleName, Cor) then
    Exit; // TagString com nome de papel que não existe no record - ignora

  if Kind.Equals('Fill') and (AObject is TShape) then
    TShape(AObject).Fill.Color := Cor

  else if Kind.Equals('Stroke') and (AObject is TShape) then
    TShape(AObject).Stroke.Color := Cor

  else if Kind.Equals('Font') and (AObject is TText) then
    TText(AObject).Color := Cor

  else if Kind.Equals('Bitmap') and (AObject is TImage) then
  begin
    if not FDominantCache.TryGetValue(TImage(AObject).Bitmap, Origem) then
    begin
      Origem := TBitmapColorHelper.GetDominantOpaqueColor(TImage(AObject).Bitmap);
      FDominantCache.Add(TImage(AObject).Bitmap, Origem);
    end;

    TImage(AObject).Bitmap.ReplaceOpaqueColor(Origem, Cor);
  end;
end;

class procedure TThemeApplier.ApplyToTree(ARoot: TFmxObject);
var
  Child: TFmxObject;
begin
  ApplyTag(ARoot, TThemeManager.Scheme);
  for Child in ARoot.Children do
    ApplyToTree(Child); // recursivo - pega containers dentro de containers
end;

end.