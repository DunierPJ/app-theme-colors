unit App.SystemBars.Android.Factory;

interface

{$SCOPEDENUMS ON}

{$IFDEF ANDROID}
uses
  { Delphi }
  System.SysUtils,
  FMX.Forms,
  FMX.Platform,
  { Component units }
  App.SystemBars,
  App.SystemBars.Android.Interfaces,
  App.SystemBars.Android.WindowFix,
  App.SystemBars.Android.InsetsCalculator,
  App.SystemBars.Android.ColorController,
  App.SystemBars.Android.VisibilityController,
  App.SystemBars.Android.EventListener,
  App.SystemBarsService;

type
  { TSystemBarsFactory }

  TSystemBarsFactory = class
  public
    class function CreateWindowServiceFix: IWindowServiceFix; static;
    class function CreateInsetsCalculator: ISystemBarsInsetsCalculator; static;
    class function CreateColorController(const AInsetsCalculator: ISystemBarsInsetsCalculator = nil): ISystemBarsColorController; static;
    class function CreateVisibilityController(const AColorController: ISystemBarsColorController = nil;
      const AInsetsCalculator: ISystemBarsInsetsCalculator = nil): ISystemBarsVisibilityController; static;
    class function CreateEventListener(const AInsetsCalculator: ISystemBarsInsetsCalculator = nil;
      const AVisibilityController: ISystemBarsVisibilityController = nil): ISystemBarsEventListener; static;
    class function CreateService(
      const AWindowServiceFix: IWindowServiceFix = nil;
      const AInsetsCalculator: ISystemBarsInsetsCalculator = nil;
      const AVisibilityController: ISystemBarsVisibilityController = nil;
      const AColorController: ISystemBarsColorController = nil;
      const AEventListener: ISystemBarsEventListener = nil
    ): ISystemBarsServiceAndroid; static;
  end;
{$ENDIF}

implementation

{$IFDEF ANDROID}

{ TSystemBarsFactory }

class function TSystemBarsFactory.CreateWindowServiceFix: IWindowServiceFix;
begin
  Result := TWindowServiceFix.Create;
end;

class function TSystemBarsFactory.CreateInsetsCalculator: ISystemBarsInsetsCalculator;
begin
  Result := TSystemBarsInsetsCalculator.Create;
end;

class function TSystemBarsFactory.CreateColorController(const AInsetsCalculator: ISystemBarsInsetsCalculator): ISystemBarsColorController;
var
  LCalculator: ISystemBarsInsetsCalculator;
begin
  if Assigned(AInsetsCalculator) then
    LCalculator := AInsetsCalculator
  else
    LCalculator := CreateInsetsCalculator;
  Result := TSystemBarsColorController.Create(LCalculator);
end;

class function TSystemBarsFactory.CreateVisibilityController(const AColorController: ISystemBarsColorController;
  const AInsetsCalculator: ISystemBarsInsetsCalculator): ISystemBarsVisibilityController;
var
  LCalculator: ISystemBarsInsetsCalculator;
  LColorCtrl: ISystemBarsColorController;
begin
  if Assigned(AInsetsCalculator) then
    LCalculator := AInsetsCalculator
  else
    LCalculator := CreateInsetsCalculator;

  if Assigned(AColorController) then
    LColorCtrl := AColorController
  else
    LColorCtrl := CreateColorController(LCalculator);

  Result := TSystemBarsVisibilityController.Create(LColorCtrl, LCalculator);
end;

class function TSystemBarsFactory.CreateEventListener(const AInsetsCalculator: ISystemBarsInsetsCalculator;
  const AVisibilityController: ISystemBarsVisibilityController): ISystemBarsEventListener;
var
  LCalculator: ISystemBarsInsetsCalculator;
  LVisCtrl: ISystemBarsVisibilityController;
begin
  if Assigned(AInsetsCalculator) then
    LCalculator := AInsetsCalculator
  else
    LCalculator := CreateInsetsCalculator;

  if Assigned(AVisibilityController) then
    LVisCtrl := AVisibilityController
  else
    LVisCtrl := CreateVisibilityController(nil, LCalculator);

  Result := TSystemBarsEventListener.Create(LCalculator, LVisCtrl);
end;

class function TSystemBarsFactory.CreateService(
  const AWindowServiceFix: IWindowServiceFix;
  const AInsetsCalculator: ISystemBarsInsetsCalculator;
  const AVisibilityController: ISystemBarsVisibilityController;
  const AColorController: ISystemBarsColorController;
  const AEventListener: ISystemBarsEventListener): ISystemBarsServiceAndroid;
begin
  Result := TSystemBarsServiceAndroid.Create(
    AWindowServiceFix,
    AInsetsCalculator,
    AVisibilityController,
    AColorController,
    AEventListener
  );
end;

{$ENDIF}

end.
