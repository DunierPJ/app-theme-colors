unit App.SystemBarsService;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  App.ColorScheme,
  App.ThemeInterfaces
  {$IFDEF ANDROID}
  , Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Os,
  Androidapi.JNI.App,
  Androidapi.Helpers
  {$ENDIF};

type
  TSystemBarsService = class(TInterfacedObject, ISystemBarsService)
  public
    procedure ApplySystemBars(const AScheme: TColorScheme; const AIsDark: Boolean);
  end;

implementation

{ TSystemBarsService }

procedure TSystemBarsService.ApplySystemBars(const AScheme: TColorScheme; const AIsDark: Boolean);
{$IFDEF ANDROID}
var
  SurfaceColor: TAlphaColor;
  IsDarkMode: Boolean;
{$ENDIF}
begin
{$IFDEF ANDROID}
  SurfaceColor := AScheme.Surface;
  IsDarkMode := AIsDark;

  // Executa em uma thread separada com pequeno atraso para sobrepor o ciclo padrão do FMX
  TThread.CreateAnonymousThread(
    procedure
    begin
      // Aguarda 150ms para garantir que o FMX terminou de renderizar a tela principal
      Sleep(150);

      TThread.Synchronize(nil,
        procedure
        var
          Window: JWindow;
          DecorView: JView;
          InsetsController: JWindowInsetsController;
          ViewFlags: Integer;
          Mask, Appearance: Integer;
        begin
          try
            if (TAndroidHelper.Activity = nil) or (TAndroidHelper.Activity.getWindow = nil) then
              Exit;

            Window := TAndroidHelper.Activity.getWindow;
            if Window = nil then Exit;

            DecorView := Window.getDecorView;
            if DecorView = nil then Exit;

            if TJBuild_VERSION.JavaClass.SDK_INT >= 21 then
            begin
              Window.clearFlags(TJWindowManager_LayoutParams.JavaClass.FLAG_TRANSLUCENT_STATUS or
                                TJWindowManager_LayoutParams.JavaClass.FLAG_TRANSLUCENT_NAVIGATION);

              Window.addFlags(TJWindowManager_LayoutParams.JavaClass.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);

              Window.setStatusBarColor(SurfaceColor);
              Window.setNavigationBarColor(SurfaceColor);
            end;

            if TJBuild_VERSION.JavaClass.SDK_INT >= 30 then
            begin
              InsetsController := Window.getInsetsController;
              if InsetsController <> nil then
              begin
                Mask := TJWindowInsetsController.JavaClass.APPEARANCE_LIGHT_STATUS_BARS or
                        TJWindowInsetsController.JavaClass.APPEARANCE_LIGHT_NAVIGATION_BARS;

                Appearance := 0;
                if not IsDarkMode then
                  Appearance := Mask;

                InsetsController.setSystemBarsAppearance(Appearance, Mask);
              end;
            end
            else
            begin
              ViewFlags := DecorView.getSystemUiVisibility;

              if TJBuild_VERSION.JavaClass.SDK_INT >= 23 then
              begin
                if not IsDarkMode then
                  ViewFlags := ViewFlags or TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
                else
                  ViewFlags := ViewFlags and not TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
              end;

              if TJBuild_VERSION.JavaClass.SDK_INT >= 26 then
              begin
                if not IsDarkMode then
                  ViewFlags := ViewFlags or TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
                else
                  ViewFlags := ViewFlags and not TJView.JavaClass.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
              end;

              DecorView.setSystemUiVisibility(ViewFlags);
            end;

          except
            on E: Exception do
            begin
              // Silencia exceções de ciclo de vida
            end;
          end;
        end);
    end).Start;
{$ENDIF}
end;

end.
