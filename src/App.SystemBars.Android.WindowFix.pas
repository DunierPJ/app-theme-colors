unit App.SystemBars.Android.WindowFix;

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
  FMX.Platform.Android,
  FMX.Platform.UI.Android,
  FMX.Platform.Screen.Android,
  App.SystemBars,
  App.SystemBars.Android.Interfaces;

type
  { TWindowServiceFix }

  TWindowServiceFix = class(TInterfacedObject, IWindowServiceFix, IFMXWindowService)
  strict private
    FDefaultWindowService: IFMXWindowService;
  public
    constructor Create;
    destructor Destroy; override;
    { IWindowServiceFix }
    function GetWindowService: IFMXWindowService;
    { IFMXWindowService }
    function FindForm(const AHandle: TWindowHandle): TCommonCustomForm;
    function CreateWindow(const AForm: TCommonCustomForm): TWindowHandle;
    procedure DestroyWindow(const AForm: TCommonCustomForm);
    procedure ReleaseWindow(const AForm: TCommonCustomForm);
    procedure SetWindowState(const AForm: TCommonCustomForm; const AState: TWindowState);
    procedure ShowWindow(const AForm: TCommonCustomForm);
    procedure HideWindow(const AForm: TCommonCustomForm);
    function ShowWindowModal(const AForm: TCommonCustomForm): TModalResult;
    procedure InvalidateWindowRect(const AForm: TCommonCustomForm; R: TRectF);
    procedure InvalidateImmediately(const AForm: TCommonCustomForm);
    procedure SetWindowRect(const AForm: TCommonCustomForm; ARect: TRectF);
    function GetWindowRect(const AForm: TCommonCustomForm): TRectF;
    function GetClientSize(const AForm: TCommonCustomForm): TPointF;
    procedure SetClientSize(const AForm: TCommonCustomForm; const ASize: TPointF);
    procedure SetWindowCaption(const AForm: TCommonCustomForm; const ACaption: string);
    procedure SetCapture(const AForm: TCommonCustomForm);
    procedure ReleaseCapture(const AForm: TCommonCustomForm);
    function ClientToScreen(const AForm: TCommonCustomForm; const Point: TPointF): TPointF;
    function ScreenToClient(const AForm: TCommonCustomForm; const Point: TPointF): TPointF;
    procedure BringToFront(const AForm: TCommonCustomForm);
    procedure SendToBack(const AForm: TCommonCustomForm);
    procedure Activate(const AForm: TCommonCustomForm);
    function GetWindowScale(const AForm: TCommonCustomForm): Single;
    function CanShowModal: Boolean;
  end;

{$ELSE}
implementation
{$ENDIF}

{$IFDEF ANDROID}
implementation

{ TWindowServiceFix }

constructor TWindowServiceFix.Create;
begin
  inherited Create;
  if TPlatformServices.Current.SupportsPlatformService(IFMXWindowService, FDefaultWindowService) then
  begin
    TPlatformServices.Current.RemovePlatformService(IFMXWindowService);
    TPlatformServices.Current.AddPlatformService(IFMXWindowService, Self);
  end;
end;

destructor TWindowServiceFix.Destroy;
begin
  if TPlatformServices.Current <> nil then
  begin
    TPlatformServices.Current.RemovePlatformService(IFMXWindowService);
    if Assigned(FDefaultWindowService) then
      TPlatformServices.Current.AddPlatformService(IFMXWindowService, FDefaultWindowService);
  end;
  inherited;
end;

function TWindowServiceFix.GetWindowService: IFMXWindowService;
begin
  Result := Self;
end;

procedure TWindowServiceFix.Activate(const AForm: TCommonCustomForm);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.Activate(AForm);
end;

procedure TWindowServiceFix.BringToFront(const AForm: TCommonCustomForm);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.BringToFront(AForm);
end;

function TWindowServiceFix.CanShowModal: Boolean;
begin
  if Assigned(FDefaultWindowService) then
    Result := FDefaultWindowService.CanShowModal
  else
    Result := False;
end;

function TWindowServiceFix.ClientToScreen(const AForm: TCommonCustomForm; const Point: TPointF): TPointF;
var
  LSystemBars: TScreenSystemBars;
begin
  if Assigned(FDefaultWindowService) then
    Result := FDefaultWindowService.ClientToScreen(AForm, Point)
  else
    Result := Point;
  if Assigned(AForm) then
  begin
    LSystemBars := AForm.SystemBars;
    if Assigned(LSystemBars) and (LSystemBars.Visibility = TScreenSystemBars.TVisibilityMode.VisibleAndOverlap) then
      Result.Y := Result.Y - LSystemBars.TappableInsets.Top;
  end;
end;

function TWindowServiceFix.CreateWindow(const AForm: TCommonCustomForm): TWindowHandle;
begin
  if Assigned(FDefaultWindowService) then
    Result := FDefaultWindowService.CreateWindow(AForm)
  else
    Result := nil;
end;

procedure TWindowServiceFix.DestroyWindow(const AForm: TCommonCustomForm);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.DestroyWindow(AForm);
end;

function TWindowServiceFix.FindForm(const AHandle: TWindowHandle): TCommonCustomForm;
begin
  if Assigned(FDefaultWindowService) then
    Result := FDefaultWindowService.FindForm(AHandle)
  else
    Result := nil;
end;

function TWindowServiceFix.GetClientSize(const AForm: TCommonCustomForm): TPointF;
begin
  if Assigned(FDefaultWindowService) then
    Result := FDefaultWindowService.GetClientSize(AForm)
  else
    Result := TPointF.Zero;
end;

function TWindowServiceFix.GetWindowRect(const AForm: TCommonCustomForm): TRectF;
begin
  if Assigned(FDefaultWindowService) then
    Result := FDefaultWindowService.GetWindowRect(AForm)
  else
    Result := TRectF.Empty;
end;

function TWindowServiceFix.GetWindowScale(const AForm: TCommonCustomForm): Single;
begin
  if Assigned(FDefaultWindowService) and (TObject(FDefaultWindowService) is TWindowServiceAndroid) then
    Result := TWindowServiceAndroid(TObject(FDefaultWindowService)).GetWindowScale(AForm)
  else
    Result := 1.0;
end;

procedure TWindowServiceFix.HideWindow(const AForm: TCommonCustomForm);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.HideWindow(AForm);
end;

procedure TWindowServiceFix.InvalidateImmediately(const AForm: TCommonCustomForm);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.InvalidateImmediately(AForm);
end;

procedure TWindowServiceFix.InvalidateWindowRect(const AForm: TCommonCustomForm; R: TRectF);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.InvalidateWindowRect(AForm, R);
end;

procedure TWindowServiceFix.ReleaseCapture(const AForm: TCommonCustomForm);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.ReleaseCapture(AForm);
end;

procedure TWindowServiceFix.ReleaseWindow(const AForm: TCommonCustomForm);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.ReleaseWindow(AForm);
end;

function TWindowServiceFix.ScreenToClient(const AForm: TCommonCustomForm; const Point: TPointF): TPointF;
var
  LSystemBars: TScreenSystemBars;
begin
  if Assigned(FDefaultWindowService) then
    Result := FDefaultWindowService.ScreenToClient(AForm, Point)
  else
    Result := Point;
  if Assigned(AForm) then
  begin
    LSystemBars := AForm.SystemBars;
    if Assigned(LSystemBars) and (LSystemBars.Visibility = TScreenSystemBars.TVisibilityMode.VisibleAndOverlap) then
      Result.Y := Result.Y + LSystemBars.TappableInsets.Top;
  end;
end;

procedure TWindowServiceFix.SendToBack(const AForm: TCommonCustomForm);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.SendToBack(AForm);
end;

procedure TWindowServiceFix.SetCapture(const AForm: TCommonCustomForm);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.SetCapture(AForm);
end;

procedure TWindowServiceFix.SetClientSize(const AForm: TCommonCustomForm; const ASize: TPointF);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.SetClientSize(AForm, ASize);
end;

procedure TWindowServiceFix.SetWindowCaption(const AForm: TCommonCustomForm; const ACaption: string);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.SetWindowCaption(AForm, ACaption);
end;

procedure TWindowServiceFix.SetWindowRect(const AForm: TCommonCustomForm; ARect: TRectF);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.SetWindowRect(AForm, ARect);
end;

procedure TWindowServiceFix.SetWindowState(const AForm: TCommonCustomForm; const AState: TWindowState);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.SetWindowState(AForm, AState);
end;

procedure TWindowServiceFix.ShowWindow(const AForm: TCommonCustomForm);
begin
  if Assigned(FDefaultWindowService) then
    FDefaultWindowService.ShowWindow(AForm);
end;

function TWindowServiceFix.ShowWindowModal(const AForm: TCommonCustomForm): TModalResult;
begin
  if Assigned(FDefaultWindowService) then
    Result := FDefaultWindowService.ShowWindowModal(AForm)
  else
    Result := mrNone;
end;

{$ENDIF}

end.
