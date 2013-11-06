unit PHP_xDebug;
{$mode objfpc}{$H+}
{**
 * Mini Edit
 *
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}

{
#Put it in php.ini

zend_extension = ext/php_xdebug.dll
xdebug.remote_handler = dbgp
xdebug.remote_mode = req
xdebug.remote_enable = On


xdebug.remote_autostart = On

xdebug.remote_port = 9000
xdebug.remote_connect_back = Off
xdebug.idekey = "XDEBUG"
#xdebug.extended_info = On
}
interface

uses
  SysUtils, Forms, StrUtils, Variants, Classes, Controls, Graphics, Contnrs, syncobjs,
  mnServers,
  dbgpServers,
  SynEdit,
  EditorDebugger, DebugClasses;

type
  TPHP_xDebug = class;

  TPHP_xDebugServer = class(TdbgpServer)
  private
    FKey: string;
  protected
    FDebug: TPHP_xDebug;
    procedure DoChanged(vListener: TmnListener); override;
  public
    destructor Destroy; override;
    property Key: string read FKey;
  end;

  { TPHP_xDebugBreakPoints }

  TPHP_xDebugBreakPoints = class(TEditorBreakPoints)
  protected
    FDebug: TPHP_xDebug;
    function GetCount: integer; override;
    function GetItems(Index: integer): TEditBreakpoint; override;
  public
    procedure Clear; override;
    procedure Toggle(FileName: string; LineNo: integer); override;
    function Found(FileName: string; LineNo: integer): boolean; override;
    procedure Add(FileName: string; LineNo: integer); override;
    procedure Remove(FileName: string; Line: integer); override; overload;
    procedure Remove(Handle: integer); override; overload;
  end;

  { TPHP_xDebugWatches }

  TPHP_xDebugWatches = class(TEditorWatches)
  protected
    FDebug: TPHP_xDebug;
    function GetCount: integer; override;
    function GetItems(Index: integer): TDebugWatchInfo; override;
  public
    procedure Clear; override;
    procedure Add(vName: string); override;
    procedure Remove(vName: string); override;
    function GetValue(vName: string; var vValue: variant; var vType: string; EvalIt: Boolean): boolean; override;
  end;

  { TPHP_xDebug }

  TPHP_xDebug = class(TEditorDebugger)
  private
    FServer: TPHP_xDebugServer;
  protected
    function CreateBreakPoints: TEditorBreakPoints; override;
    function CreateWatches: TEditorWatches; override;
    procedure DoShowFile(const Key, FileName: string; Line: integer; vCallStack: TCallStackItems);

    procedure Start;
    procedure Stop;
    procedure Reset;
    procedure Resume;
    procedure StepInto;
    procedure StepOver;
    procedure StepOut;
    procedure Run;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Action(AAction: TDebugAction); override;
    function GetState: TDebugStates; override;
    procedure Lock; override;
    procedure Unlock; override;
    function GetKey: string; override;
  end;

implementation

{ TPHP_xDebugWatches }

function TPHP_xDebugWatches.GetCount: integer;
begin
  with FDebug.FServer do
    Result := Watches.Count;
end;

function TPHP_xDebugWatches.GetItems(Index: integer): TDebugWatchInfo;
var
  aWt: TdbgpWatch;
begin
  with FDebug.FServer do
    aWt := Watches[Index];
  Result:= aWt.Info;
end;

procedure TPHP_xDebugWatches.Clear;
begin
  with FDebug.FServer do
    Watches.Clear;
end;

procedure TPHP_xDebugWatches.Add(vName: string);
begin
  with FDebug.FServer do
    Watches.AddWatch(vName);
end;

procedure TPHP_xDebugWatches.Remove(vName: string);
begin
  with FDebug.FServer do
    Watches.RemoveWatch(vName);
end;

function TPHP_xDebugWatches.GetValue(vName: string; var vValue: variant; var vType: string; EvalIt: Boolean): boolean;
var
  aAction: TdbgpCustomGet;
begin
  Result := False;
  if dbsRunning in FDebug.GetState then   //there is a connection from XDebug
  begin
    if EvalIt then
      aAction := TdbgpEval.Create
    else
      aAction := TdbgpGetWatchInstance.Create;
    aAction.CreateEvent;
    aAction.Info.VarName := vName;
    with FDebug.FServer do
    begin
      AddAction(aAction);
      Resume;
      aAction.Event.WaitFor(30000);
      begin
        vValue := aAction.Info.Value;
        vType := aAction.Info.VarType;
        Result := True;
      end;
      ExtractAction(aAction);
      aAction.Free;
    end;
  end;
end;

{ TPHP_xDebugBreakPoints }

function TPHP_xDebugBreakPoints.GetCount: integer;
begin
  with FDebug.FServer do
    Result := Breakpoints.Count;
end;

function TPHP_xDebugBreakPoints.GetItems(Index: integer): TEditBreakpoint;
var
  aBP: TdbgpBreakpoint;
begin
  with FDebug.FServer do
    aBP := Breakpoints[Index];
  Result.FileName := aBP.FileName;
  Result.Handle := aBP.Handle;
  Result.Line := aBP.Line;
end;

procedure TPHP_xDebugBreakPoints.Clear;
begin
  with FDebug.FServer do
    Breakpoints.Clear;
end;

procedure TPHP_xDebugBreakPoints.Toggle(FileName: string; LineNo: integer);
begin
  with FDebug.FServer do
    Breakpoints.Toggle(FileName, LineNo);
end;

function TPHP_xDebugBreakPoints.Found(FileName: string; LineNo: integer): boolean;
begin
  with FDebug.FServer do
    Result := Breakpoints.Find(FileName, LineNo) <> nil;
end;

procedure TPHP_xDebugBreakPoints.Add(FileName: string; LineNo: integer);
begin
  with FDebug.FServer do
    Breakpoints.Add(FileName, LineNo);
end;

procedure TPHP_xDebugBreakPoints.Remove(FileName: string; Line: integer);
var
  aBP: TdbgpBreakpoint;
begin
  with FDebug.FServer do
    aBP := Breakpoints.Find(FileName, Line);
  if aBP <> nil then
    with FDebug.FServer do
      Breakpoints.Remove(aBP);
end;

procedure TPHP_xDebugBreakPoints.Remove(Handle: integer);
begin
  with FDebug.FServer do
    Breakpoints.Remove(Handle);
end;

{ TPHP_xDebug }

function TPHP_xDebug.CreateBreakPoints: TEditorBreakPoints;
begin
  Result := TPHP_xDebugBreakPoints.Create;
  (Result as TPHP_xDebugBreakPoints).FDebug := Self;
end;

function TPHP_xDebug.CreateWatches: TEditorWatches;
begin
  Result := TPHP_xDebugWatches.Create;
  (Result as TPHP_xDebugWatches).FDebug := Self;
end;

procedure TPHP_xDebug.DoShowFile(const Key, FileName: string; Line: integer; vCallStack: TCallStackItems);
begin
  SetExecutedLine(Key, FileName, Line, vCallStack);
end;

constructor TPHP_xDebug.Create;
begin
  inherited Create;
  FServer := TPHP_xDebugServer.Create(nil);
  FServer.FDebug := Self;
  DBGP.OnShowFile := @DoShowFile;
end;

destructor TPHP_xDebug.Destroy;
begin
  FreeAndNil(FServer);
  DBGP.OnShowFile := nil;
  inherited;
end;

procedure TPHP_xDebug.Action(AAction: TDebugAction);
begin
  case AAction of
    dbaStart: Start;
    dbaStop: Stop;
    dbaReset: Reset;
    dbaResume: Resume;
    dbaStepInto: StepInto;
    dbaStepOver: StepOver;
    dbaStepOut: StepOut;
    dbaRun: Run;
  end;
end;

function TPHP_xDebug.GetState: TDebugStates;
begin
  Result := [];
  if FServer.Active then
    Result := Result + [dbsActive];
  if FServer.IsRuning then
    Result := Result + [dbsRunning];
end;

procedure TPHP_xDebug.Start;
begin
  FServer.Start;
end;

procedure TPHP_xDebug.Stop;
var
  aAction: TdbgpDetach;
begin
  if FServer.IsRuning then
  begin
    FServer.Clear;
    aAction := TdbgpDetach.Create;
    aAction.CreateEvent;
    FServer.AddAction(aAction);
    FServer.Resume;
    aAction.Event.WaitFor(30000);
    FServer.ExtractAction(aAction);
    aAction.Free;
  end;
  FServer.Stop;
end;

procedure TPHP_xDebug.Reset;
begin
  FServer.Clear; //no need to any exists actions
  FServer.AddAction(TdbgpStop.Create);
  FServer.AddAction(TdbgpGetCurrent.Create);
  FServer.Resume;
end;

procedure TPHP_xDebug.Resume;
begin
  FServer.AddAction(TdbgpDetach.Create);
  FServer.AddAction(TdbgpGetCurrent.Create);
  FServer.Resume;
end;

procedure TPHP_xDebug.StepInto;
begin
  FServer.AddAction(TdbgpStepInto.Create);
  FServer.AddAction(TdbgpGetWatches.Create);
  FServer.AddAction(TdbgpGetCurrent.Create);
  FServer.Resume;
end;

procedure TPHP_xDebug.StepOver;
begin
  FServer.AddAction(TdbgpStepOver.Create);
  FServer.AddAction(TdbgpGetWatches.Create);
  FServer.AddAction(TdbgpGetCurrent.Create);
  FServer.Resume;
end;

procedure TPHP_xDebug.StepOut;
begin
  FServer.AddAction(TdbgpStepOut.Create);
  FServer.AddAction(TdbgpGetWatches.Create);
  FServer.AddAction(TdbgpGetCurrent.Create);
  FServer.Resume;
end;

procedure TPHP_xDebug.Run;
begin
  FServer.AddAction(TdbgpRun.Create);
  FServer.AddAction(TdbgpGetWatches.Create);
  FServer.AddAction(TdbgpGetCurrent.Create);
  FServer.Resume;
end;

procedure TPHP_xDebug.Lock;
begin
  DBGP.Lock.Enter;
end;

procedure TPHP_xDebug.Unlock;
begin
  DBGP.Lock.Leave;
end;

function TPHP_xDebug.GetKey: string;
begin
  Result := FServer.Key;
end;

procedure TPHP_xDebugServer.DoChanged(vListener: TmnListener);
begin
  inherited;
end;

destructor TPHP_xDebugServer.Destroy;
begin
  inherited;
end;

initialization
//  Addons.Add('Debug', 'XDebug', TPHP_xDebug);//must not created /??!!!
end.

