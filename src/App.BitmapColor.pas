unit App.BitmapColor;

interface

uses
  System.UITypes, 
  System.Generics.Collections, 
  FMX.Graphics, 
  FMX.Types;

type
  TBitmapHelper = class helper for TBitmap
  public
    /// <summary>Retorna a cor opaca (Alpha = 255) que mais aparece no bitmap.</summary>
    function GetDominantOpaqueColor: TAlphaColor;
    
    /// <summary>Substitui a cor dos pixels mantendo o canal de transparência (Alpha) original.</summary>
    procedure ReplaceOpaqueColor(const ANewColor: TAlphaColor; const ASourceColor: TAlphaColor = TAlphaColorRec.Null);
  end;

implementation

function TBitmapHelper.GetDominantOpaqueColor: TAlphaColor;
var
  Data: TBitmapData;
  X, Y: Integer;
  Pixel: TAlphaColor;
  Count: Integer;
  Counts: TDictionary<TAlphaColor, Integer>;
  Pair: TPair<TAlphaColor, Integer>;
  BestColor: TAlphaColor;
  BestCount: Integer;
begin
  BestColor := TAlphaColorRec.Black;
  if (Self = nil) or IsEmpty then
    Exit(BestColor);

  Counts := TDictionary<TAlphaColor, Integer>.Create;
  try
    if Map(TMapAccess.Read, Data) then
    try
      for Y := 0 to Height - 1 do
        for X := 0 to Width - 1 do
        begin
          Pixel := Data.GetPixel(X, Y);
          if TAlphaColorRec(Pixel).A = 255 then
          begin
            if not Counts.TryGetValue(Pixel, Count) then
              Count := 0;
            Counts.AddOrSetValue(Pixel, Count + 1);
          end;
        end;
    finally
      Unmap(Data);
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

procedure TBitmapHelper.ReplaceOpaqueColor(const ANewColor: TAlphaColor; const ASourceColor: TAlphaColor = TAlphaColorRec.Null);
var
  Data: TBitmapData;
  X, Y: Integer;
  Pixel: TAlphaColor;
  OrigAlpha: Byte;
  TargetRGB: TAlphaColor;
  TargetSource: TAlphaColor;
begin
  if (Self = nil) or IsEmpty then
    Exit;

  TargetSource := ASourceColor;
  if TargetSource = TAlphaColorRec.Null then
    TargetSource := GetDominantOpaqueColor;

  TargetRGB := ANewColor and $00FFFFFF;

  if Map(TMapAccess.ReadWrite, Data) then
  try
    for Y := 0 to Height - 1 do
      for X := 0 to Width - 1 do
      begin
        Pixel := Data.GetPixel(X, Y);
        OrigAlpha := TAlphaColorRec(Pixel).A;
        if OrigAlpha > 0 then
        begin
          if (TargetSource = TAlphaColorRec.Null) or 
             (Pixel = TargetSource) or 
             ((Pixel and $00FFFFFF) = (TargetSource and $00FFFFFF)) then
          begin
            Data.SetPixel(X, Y, (OrigAlpha shl 24) or TargetRGB);
          end;
        end;
      end;
  finally
    Unmap(Data);
  end;
end;

end.