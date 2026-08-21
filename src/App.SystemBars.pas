unit App.SystemBars;

interface

{$SCOPEDENUMS ON}

uses
  { Delphi }
  System.SysUtils,
  System.Classes,
  System.Messaging,
  System.Types,
  System.UITypes,
  System.Generics.Collections,
  FMX.Forms;

type
  { TScreenSystemBars }

  TScreenSystemBars = class(TPersistent)
  public
    type
      TVisibilityMode = TFormSystemStatusBar.TVisibilityMode;
  public
    const
      DefaultNavigationBarBackgroundColor = TAlphaColorRec.Null;
      DefaultStatusBarBackgroundColor = TFormSystemStatusBar.DefaultBackgroundColor;
      DefaultVisibility = TFormSystemStatusBar.DefaultVisibility;
  {$REGION 'internal'}
  public
    type
      Exception = class(System.SysUtils.Exception);

    /// <summary>Called from a form as Sender always when the form's insets has changed</summary>
      TInsetsChangeMessage = class(TMessage)
      private
        FInsets: TRectF;
        FTappableInsets: TRectF;
      public
        constructor Create(const AInsets, ATappableInsets: TRectF);
        property Insets: TRectF read FInsets;
        property TappableInsets: TRectF read FTappableInsets;
      end;

      IFMXWindowSystemBarsService = interface
        ['{124BEBCA-0F61-4A94-92E4-CA279E1BE2E3}']
        function GetInsets(const AForm: TCommonCustomForm): TRectF;
        function GetTappableInsets(const AForm: TCommonCustomForm): TRectF;
        procedure SetStatusBarBackgroundColor(const AForm: TCommonCustomForm; const AColor: TAlphaColor);
        procedure SetNavigationBarBackgroundColor(const AForm: TCommonCustomForm; const AColor: TAlphaColor);
        procedure SetVisibility(const AForm: TCommonCustomForm; const AMode: TScreenSystemBars.TVisibilityMode);
      end;
  strict private
    [Weak]
    FForm: TCommonCustomForm;
    FFormInsetsChangeMessageId: Integer;
    FInsets: TRectF;
    FNavigationBarBackgroundColor: TAlphaColor;
    FOnInsetsChange: TNotifyEvent;
    FTappableInsets: TRectF;
    procedure FormInsetsChange(const ASender: TObject; const AMessage: TMessage);
    function GetStatusBarBackgroundColor: TAlphaColor;
    function GetVisibility: TVisibilityMode;
    procedure SetNavigationBarBackgroundColor(const AValue: TAlphaColor);
    procedure SetStatusBarBackgroundColor(const AValue: TAlphaColor);
    procedure SetVisibility(const AValue: TVisibilityMode);
  protected
    procedure AssignTo(ADest: TPersistent); override;
  {$ENDREGION}
  public
    constructor Create(const AForm: TCommonCustomForm);
    destructor Destroy; override;
    property Insets: TRectF read FInsets;
    property TappableInsets: TRectF read FTappableInsets;
    property OnInsetsChange: TNotifyEvent read FOnInsetsChange write FOnInsetsChange;
  published
    property NavigationBarBackgroundColor: TAlphaColor read FNavigationBarBackgroundColor write
      SetNavigationBarBackgroundColor default DefaultNavigationBarBackgroundColor;
    property StatusBarBackgroundColor: TAlphaColor read GetStatusBarBackgroundColor write SetStatusBarBackgroundColor default
      DefaultStatusBarBackgroundColor;
    property Visibility: TVisibilityMode read GetVisibility write SetVisibility default DefaultVisibility;
  end;

  { TScreenHelper }

  TScreenHelper = class helper for TCommonCustomForm
  {$REGION 'internal'}
  strict private
    class var
      FAfterCreateFormHandleMessageId: Integer;
      FDictionary: TObjectDictionary<TCommonCustomForm, TScreenSystemBars>;
      FFormReleasedMessageId: Integer;
    class procedure AfterCreateFormHandle(const ASender: TObject; const AMessage: TMessage); static;
    class constructor Create;
    class destructor Destroy;
    class procedure FormReleased(const ASender: TObject; const AMessage: TMessage); static;
    class function GeTScreenSystemBars(AForm: TCommonCustomForm): TScreenSystemBars; static;
  strict private
    function GetOnSystemBarsInsetsChange: TNotifyEvent;
    function GetSystemBars: TScreenSystemBars;
    procedure SetOnSystemBarsInsetsChange(const AValue: TNotifyEvent);
    procedure SetSystemBars(const AValue: TScreenSystemBars);
  {$ENDREGION}
  public
    property SystemBars: TScreenSystemBars read GetSystemBars write SetSystemBars;
    property OnSystemBarsInsetsChange: TNotifyEvent read GetOnSystemBarsInsetsChange write SetOnSystemBarsInsetsChange;
  end;

implementation

uses
  { Delphi }
  FMX.platform;

{ TScreenSystemBars }

procedure TScreenSystemBars.AssignTo(ADest: TPersistent);
var
  LDestSystemBars: TScreenSystemBars;
begin
  if ADest is TScreenSystemBars then
  begin
    LDestSystemBars := TScreenSystemBars(ADest);
    LDestSystemBars.NavigationBarBackgroundColor := NavigationBarBackgroundColor;
    LDestSystemBars.StatusBarBackgroundColor := StatusBarBackgroundColor;
    LDestSystemBars.Visibility := Visibility;
  end
  else
    inherited;
end;

constructor TScreenSystemBars.Create(const AForm: TCommonCustomForm);
begin
  FForm := AForm;
  FNavigationBarBackgroundColor := DefaultNavigationBarBackgroundColor;
  FFormInsetsChangeMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TInsetsChangeMessage, FormInsetsChange);
end;

destructor TScreenSystemBars.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TInsetsChangeMessage, FFormInsetsChangeMessageId);
  inherited;
end;

procedure TScreenSystemBars.FormInsetsChange(const ASender: TObject; const AMessage: TMessage);
begin
  if ASender = FForm then
  begin
    FInsets := TInsetsChangeMessage(AMessage).Insets;
    FTappableInsets := TInsetsChangeMessage(AMessage).TappableInsets;
    if Assigned(FOnInsetsChange) then
      FOnInsetsChange(FForm);
  end;
end;

function TScreenSystemBars.GetStatusBarBackgroundColor: TAlphaColor;
begin
  Result := FForm.SystemStatusBar.BackgroundColor;
end;

function TScreenSystemBars.GetVisibility: TVisibilityMode;
begin
  Result := FForm.SystemStatusBar.Visibility;
end;

procedure TScreenSystemBars.SetNavigationBarBackgroundColor(const AValue: TAlphaColor);
var
  LService: IFMXWindowSystemBarsService;
begin
  if FNavigationBarBackgroundColor <> AValue then
  begin
    FNavigationBarBackgroundColor := AValue;
    if TPlatformServices.Current.SupportsPlatformService(IFMXWindowSystemBarsService, LService) then
      LService.SetNavigationBarBackgroundColor(FForm, FNavigationBarBackgroundColor);
  end;
end;

procedure TScreenSystemBars.SetStatusBarBackgroundColor(const AValue: TAlphaColor);
begin
  FForm.SystemStatusBar.BackgroundColor := AValue;
end;

procedure TScreenSystemBars.SetVisibility(const AValue: TVisibilityMode);
begin
  FForm.SystemStatusBar.Visibility := AValue;
end;

{ TScreenSystemBars.TInsetsChangeMessage }

constructor TScreenSystemBars.TInsetsChangeMessage.Create(const AInsets, ATappableInsets: TRectF);
begin
  inherited Create;
  FInsets := AInsets;
  FTappableInsets := ATappableInsets;
end;

{ TScreenHelper }

class procedure TScreenHelper.AfterCreateFormHandle(const ASender: TObject; const AMessage: TMessage);
begin
  if ASender is TCommonCustomForm then
    TCommonCustomForm(ASender).SystemBars;
end;

class constructor TScreenHelper.Create;
begin
  FDictionary := TObjectDictionary<TCommonCustomForm, TScreenSystemBars>.Create([doOwnsValues]);
  FAfterCreateFormHandleMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TAfterCreateFormHandle,
    AfterCreateFormHandle);
  FFormReleasedMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TFormReleasedMessage, FormReleased);
end;

class destructor TScreenHelper.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TFormReleasedMessage, FFormReleasedMessageId);
  TMessageManager.DefaultManager.Unsubscribe(TAfterCreateFormHandle, FAfterCreateFormHandleMessageId);
  FreeAndNil(FDictionary);
end;

class procedure TScreenHelper.FormReleased(const ASender: TObject; const AMessage: TMessage);
begin
  if ASender is TCommonCustomForm then
    FDictionary.Remove(TCommonCustomForm(ASender));
end;

class function TScreenHelper.GeTScreenSystemBars(AForm: TCommonCustomForm): TScreenSystemBars;
begin
  if not Assigned(AForm) then
    Exit(nil);
  if not FDictionary.TryGetValue(AForm, Result) then
  begin
    if (csDestroying in AForm.ComponentState) or (TFmxFormState.Released in AForm.FormState) then
      Exit(nil);
    Result := TScreenSystemBars.Create(AForm);
    FDictionary.Add(AForm, Result);
  end;
end;

function TScreenHelper.GetOnSystemBarsInsetsChange: TNotifyEvent;
begin
  Result := SystemBars.OnInsetsChange;
end;

function TScreenHelper.GetSystemBars: TScreenSystemBars;
begin
  Result := GeTScreenSystemBars(Self);
end;

procedure TScreenHelper.SetOnSystemBarsInsetsChange(const AValue: TNotifyEvent);
begin
  SystemBars.OnInsetsChange := AValue;
end;

procedure TScreenHelper.SetSystemBars(const AValue: TScreenSystemBars);
begin
  SystemBars.Assign(AValue);
end;

end.

