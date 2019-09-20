{                                                                      }
{    TIdHTTPProgress - Extendend TIdHTTP to show progress download     }
{                                                                      }
{    Creted in https://stackoverflow.com/questions/28457925/how-to-download-a-file-with-progress-with-idhttp-via-https   }
{                                                                      }
{ Fixed and adapted to Lazarus and Delphi by Giovani Da Cruz           }
{                                                                      }
{ Please visit: https://showdelphi.com.br                              }
{----------------------------------------------------------------------}
unit util.download;

interface

uses
  Classes, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  IdSSLOpenSSL;

{$M+}

type
  TIdHTTPProgress = class(TIdHTTP)
  private
    FProgress: Integer;
    FBytesToTransfer: Int64;
    FOnChange: TNotifyEvent;
    IOHndl: TIdSSLIOHandlerSocketOpenSSL;
    procedure HTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
    procedure HTTPWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
    procedure HTTPWorkEnd(Sender: TObject; AWorkMode: TWorkMode);
    procedure SetProgress(const Value: Integer);
    procedure SetOnChange(const Value: TNotifyEvent);
  public
    constructor Create(AOwner: TComponent);
    procedure DownloadFile(const aFileUrl: string; const aDestinationFile: String);
  published
    property Progress: Integer read FProgress write SetProgress;
    property BytesToTransfer: Int64 read FBytesToTransfer;
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
  end;

implementation

uses
  Sysutils;

{ TIdHTTPProgress }

constructor TIdHTTPProgress.Create(AOwner: TComponent);
begin
  inherited;
  IOHndl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  Request.BasicAuthentication := True;
  HandleRedirects := True;
  IOHandler := IOHndl;
  ReadTimeout := 30000;

  {$IFDEF FPC}
  OnWork := @HTTPWork;
  OnWorkBegin := @HTTPWorkBegin;
  OnWorkEnd := @HTTPWorkEnd;
  {$ELSE}
  OnWork := HTTPWork;
  OnWorkBegin := HTTPWorkBegin;
  OnWorkEnd := HTTPWorkEnd;
  {$ENDIF}
end;

procedure TIdHTTPProgress.DownloadFile(const aFileUrl: string; const aDestinationFile: String);
var
  LDestStream: TFileStream;
  aPath: String;
begin
  Progress := 0;
  FBytesToTransfer := 0;
  aPath := ExtractFilePath(aDestinationFile);
  if aPath <> '' then
    ForceDirectories(aPath);

  LDestStream := TFileStream.Create(aDestinationFile, fmCreate);
  try
    Get(aFileUrl, LDestStream);
  finally
    FreeAndNil(LDestStream);
  end;
end;

procedure TIdHTTPProgress.HTTPWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
begin
  if BytesToTransfer = 0 then // No Update File
    Exit;

  Progress := Round((AWorkCount / BytesToTransfer) * 100);
end;

procedure TIdHTTPProgress.HTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
begin
  FBytesToTransfer := AWorkCountMax;
end;

procedure TIdHTTPProgress.HTTPWorkEnd(Sender: TObject; AWorkMode: TWorkMode);
begin
  FBytesToTransfer := 0;
  Progress := 100;
end;

procedure TIdHTTPProgress.SetOnChange(const Value: TNotifyEvent);
begin
  FOnChange := Value;
end;

procedure TIdHTTPProgress.SetProgress(const Value: Integer);
begin
  FProgress := Value;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

end.

