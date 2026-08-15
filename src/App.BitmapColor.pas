unit App.BitmapColor;

interface

uses
  System.UITypes, System.Generics.Collections, FMX.Graphics, FMX.Types;

type
  TBitmapColorHelper = class
  public
    /// <summary>Retorna a cor opaca (Alpha = 255) que mais aparece no bitmap.
    /// Usado como "cor de origem" pra ReplaceOpaqueColor sem precisar fixar
    /// preto/branco na mão.</summary>
    class function GetDominantOpaqueColor(ABitmap: TBitmap): TAlphaColor; static;
  end;

implementation

class function TBitmapColorHelper.GetDominantOpaqueColor(ABitmap: TBitmap): TAlphaColor;
var
  Data: TBitmapData;
  X, Y: Integer;
  Pixel: TAlphaColor;
  Counts: TDictionary<TAlphaColor, Integer>;
  Pair: TPair<TAlphaColor, Integer>;
  BestColor: TAlphaColor;
  BestCount: Integer;
begin
  BestColor := TAlphaColorRec.Black; // fallback se não achar nenhum pixel opaco
  if (ABitmap = nil) or ABitmap.IsEmpty then
    Exit(BestColor);

  Counts := TDictionary<TAlphaColor, Integer>.Create;
  try
    if ABitmap.Map(TMapAccess.Read, Data) then
    try
      for Y := 0 to ABitmap.Height - 1 do
        for X := 0 to ABitmap.Width - 1 do
        begin
          Pixel := Data.GetPixel(X, Y);
          if TAlphaColorRec(Pixel).A = 255 then // só pixel 100% opaco entra na contagem
            Counts.AddOrSetValue(Pixel, Counts.GetValueOrDefault(Pixel, 0) + 1);
        end;
    finally
      ABitmap.Unmap(Data);
    end;

    BestCount := 0;
    for Pair in Counts do
      if Pair.Value > BestCount then
      begin
        BestCount := Pair.Value;
        BestColor := Pair.Key;
      end;
  finally
    Counts.Free;
  end;

  Result := BestColor;
end;

end.