{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: JvExControls.pas, released on 2004-01-04

The Initial Developer of the Original Code is Andreas Hausladen [Andreas.Hausladen@gmx.de]
Portions created by Andreas Hausladen are Copyright (C) 2004 Andreas Hausladen.
All Rights Reserved.

Contributor(s): -

Last Modified: 2004-01-16

You may retrieve the latest version of this file at the Project JEDI's JVCL home page,
located at http://jvcl.sourceforge.net

Known Issues:
-----------------------------------------------------------------------------}
{$I jvcl.inc}

unit JvExControls;
interface
uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF MSWINDOWS}
  {$IFDEF VCL}
  Messages, Graphics, Controls, Forms,
  {$ENDIF VCL}
  {$IFDEF VisualCLX}
  Qt, QTypes, QGraphics, QControls, QWindows, QForms,
  {$ENDIF VisualCLX}
  Classes, SysUtils,
  JvThemes;

{$IFDEF VCL}
 {$DEFINE NeedMouseEnterLeave}
{$ELSE}
 {$IF not declared(PatchedVCLX)}
  {$DEFINE NeedMouseEnterLeave}
 {$IFEND}
{$ENDIF VCL}

type
  TDlgCode = (
    dcWantAllKeys, dcWantArrows, dcWantTab, dcWantChars,
    dcButton,
    dcNative // if dcNative is in the set the native functions are used and DoGetDlgCode is ignored
  );
  TDlgCodes = set of TDlgCode;

{$IFDEF VisualCLX}
  HWND = QWindows.HWND;
{$ENDIF VisualCLX}

const
  dcWantMessage = dcWantAllKeys;

type
  IJvControlEvents = interface
    ['{61FC57FF-D4DA-4840-B871-63DE804E9921}']
    procedure VisibleChanged;
    procedure EnabledChanged;
    procedure TextChanged;
    procedure FontChanged;
    procedure ColorChanged;
    procedure ParentFontChanged;
    procedure ParentColorChanged;
    procedure ParentShowHintChanged;
    function WantKey(Key: Integer; Shift: TShiftState;
      const KeyText: WideString): Boolean; // CM_DIALOGCHAR
    function HintShow(var HintInfo: THintInfo): Boolean;
    function HitTest(X, Y: Integer): Boolean; // CM_HITTEST
    procedure MouseEnter(AControl: TControl);
    procedure MouseLeave(AControl: TControl);
    function DoPaintBackground(Canvas: TCanvas; Param: Integer): Boolean; // WM_ERASEBKGND
    procedure DoFocusChanged(Control: TWinControl);
    {$IFDEF VCL}
    procedure SetAutoSize(Value: Boolean);
    {$ENDIF VCL}
  end;

  IJvWinControlEvents = interface
    ['{B5F7FB62-78F0-481D-AFF4-7A24ED6776A0}']
    procedure CursorChanged;
    procedure ShowingChanged;
    procedure ShowHintChanged;
    procedure ControlsListChanging(Control: TControl; Inserting: Boolean);
    procedure ControlsListChanged(Control: TControl; Inserting: Boolean);
    procedure DoGetDlgCode(var Code: TDlgCodes); // WM_GETDLGCODE
    procedure DoSetFocus(FocusedWnd: HWND);  // WM_SETFOCUS
    procedure DoKillFocus(FocusedWnd: HWND); // WM_KILLFOCUS
  end;

  IJvCustomControlEvents = interface
    ['{7804BD3A-D7A5-4314-9259-6DE08A0DC38A}']
  end;

const
  CM_DENYSUBCLASSING = JvThemes.CM_DENYSUBCLASSING;

type
  { Add IJvDenySubClassing to the base class list if the control should not
    be themed by the ThemeManager (www.delphi-gems.de).
    This only works with JvExVCL derived classes. }
  IJvDenySubClassing = interface
    ['{76942BC0-2A6E-4DC4-BFC9-8E110DB7F601}']
  end;

{$IFDEF VisualCLX}
const
  CM_FOCUSCHANGED = CM_BASE + 17; // VCL Controls: CM_BASE + 7

type
  TCMFocusChanged = record
    Msg: Cardinal;
    Unused: Integer;
    Sender: TWinControl;
    Result: Longint;
  end;
{$ENDIF VisualCLX}


type
  JV_CONTROL_EVENTS(Control)
  JV_WINCONTROL_EVENTS(WinControl)

  JV_CONTROL_EVENTS_BEGIN(GraphicControl)
  {$IFDEF VisualCLX}
  private
    FText: TCaption; // TControl does not save the Caption property
  protected
    function GetText: TCaption; override;
    procedure SetText(const Value: TCaption); override;
  {$ENDIF VisualCLX}
  JV_CONTROL_EVENTS_END(GraphicControl)
  JV_CUSTOMCONTROL_EVENTS(CustomControl)
  JV_CUSTOMCONTROL_EVENTS(HintWindow)


{$IFDEF VCL}
function ShiftStateToKeyData(Shift: TShiftState): Longint;

function InheritMsg(Instance: TControl; Msg: Integer; WParam, LParam: Integer): Integer; overload;
function InheritMsg(Instance: TControl; Msg: Integer): Integer; overload;
procedure DispatchMsg(Instance: TControl; var Msg);

procedure Control_ControlsListChanging(Instance: TControl; Control: TControl;
  Inserting: Boolean);
procedure Control_ControlsListChanged(Instance: TControl; Control: TControl;
  Inserting: Boolean);

{$IFNDEF COMPILER6_UP}
procedure TOpenControl_SetAutoSize(Instance: TControl; Value: Boolean);
{$ENDIF !COMPILER6_UP}
{$ENDIF VCL}

{$IFDEF VisualCLX}
function WidgetControl_Painting(Instance: TWidgetControl; Canvas: TCanvas;
  EventRegion: QRegionH): IInterface;
  // - returns NIL if the Instance is in csDestroying.
  // - enters the painting and returns an interface that leaves the painting when
  //   is is released.
procedure WidgetControl_DefaultPaint(Instance: TWidgetControl; Canvas: TCanvas);

function TWidgetControl_NeedKey(Instance: TWidgetControl; Key: Integer;
  Shift: TShiftState; const KeyText: WideString; InheritedValue: Boolean): Boolean;
{$ENDIF VisualCLX}

implementation

{$IFDEF VCL}

function ShiftStateToKeyData(Shift: TShiftState): Longint;
const
  AltMask = $20000000;
begin
  Result := 0;
  if ssAlt in Shift then
    Result := Result or AltMask;
end;

type
  TDisptachMethod = procedure(Self: TObject; var Msg: TMessage);

function InheritMsg(Instance: TControl; Msg: Integer; WParam, LParam: Integer): Integer;
var
  Proc: TDisptachMethod;
  Mesg: TMessage;
begin
  Mesg.Msg := Msg;
  Mesg.WParam := WParam;
  Mesg.LParam := LParam;
  Mesg.Result := 0;
  Proc := @TObject.Dispatch;
  Proc(Instance, Mesg);
  Result := Mesg.Result;
end;

function InheritMsg(Instance: TControl; Msg: Integer): Integer;
begin
  Result := InheritMsg(Instance, Msg, 0, 0);
end;

procedure DispatchMsg(Instance: TControl; var Msg);
var
  Temp: IJvDenySubClassing;
  IntfControl: IJvControlEvents;
  IntfWinControl: IJvWinControlEvents;
  PMsg: PMessage;
  CallInherited: Boolean;
  Canvas: TCanvas;
  DlgCodes: TDlgCodes;
begin
  CallInherited := True;
  PMsg := @Msg;

  if PMsg^.Msg = CM_DENYSUBCLASSING then
  begin
    PMsg^.Result := Ord(Instance.GetInterface(IJvDenySubClassing, Temp));
    Temp := nil; // does not destroy the control because it is derived from TComponent
   // Let the control handle CM_DENYSUBCLASSING the old way, too.
  end;

  { GetInterface is no problem because Instance is a TComponent derived class that
    is not released by an interface "Release". }
  if Instance.GetInterface(IJvControlEvents, IntfControl) then
  begin
    CallInherited := False;
    with IntfControl do
      case PMsg^.Msg of
        CM_VISIBLECHANGED:
          VisibleChanged;
        CM_ENABLEDCHANGED:
          EnabledChanged;
        CM_FONTCHANGED:
          FontChanged;
        CM_COLORCHANGED:
          ColorChanged;
        CM_PARENTFONTCHANGED:
          ParentFontChanged;
        CM_PARENTCOLORCHANGED:
          ParentColorChanged;
        CM_PARENTSHOWHINTCHANGED:
          ParentShowHintChanged;
        CM_TEXTCHANGED:
          TextChanged;
        CM_HINTSHOW:
          PMsg^.Result := Integer(HintShow(TCMHintShow(PMsg^).HintInfo^));
        CM_HITTEST:
          with TCMHitTest(PMsg^) do
            Result := Integer(HitTest(XPos, YPos));
        CM_MOUSEENTER:
            MouseEnter(TControl(PMsg^.LParam));
        CM_MOUSELEAVE:
            MouseLeave(TControl(PMsg^.LParam));
        CM_DIALOGCHAR:
          with TCMDialogChar(PMsg^) do
            Result := Ord(WantKey(CharCode, KeyDataToShiftState(KeyData), WideChar(CharCode)));
        // CM_FOCUSCHANGED: handled by a message handler in the JvExVCL classes

        WM_ERASEBKGND:
          begin
            Canvas := TCanvas.Create;
            try
              Canvas.Handle := HDC(PMsg^.WParam);
              PMsg^.Result := Ord(DoPaintBackground(Canvas, PMsg^.LParam));
            finally
              Canvas.Handle := 0;
              Canvas.Free;
            end;
          end
      else
        CallInherited := True;
      end;
  end;

  if CallInherited then
  begin
    if Instance.GetInterface(IJvWinControlEvents, IntfWinControl) then
    begin
      CallInherited := False;
      with IntfWinControl do
        case PMsg^.Msg of
          CM_CURSORCHANGED:
            CursorChanged;
          CM_SHOWINGCHANGED:
            ShowingChanged;
          CM_SHOWHINTCHANGED:
            ShowHintChanged;
          CM_CONTROLLISTCHANGE:
            if PMsg^.LParam <> 0 then
              ControlsListChanging(TControl(PMsg^.WParam), True)
            else
              ControlsListChanged(TControl(PMsg^.WParam), False);
          CM_CONTROLCHANGE:
            if PMsg^.LParam = 0 then
              ControlsListChanging(TControl(PMsg^.WParam), False)
            else
              ControlsListChanged(TControl(PMsg^.WParam), True);

          WM_GETDLGCODE:
            begin
              PMsg^.Result := InheritMsg(Instance, PMsg^.Msg, PMsg^.WParam, PMsg^.LParam);

              DlgCodes := [dcNative];
              if PMsg^.Result and DLGC_WANTARROWS <> 0 then
                Include(DlgCodes, dcWantArrows);
              if PMsg^.Result and DLGC_WANTTAB <> 0 then
                Include(DlgCodes, dcWantTab);
              if PMsg^.Result and DLGC_WANTALLKEYS <> 0 then
                Include(DlgCodes, dcWantAllKeys);
              if PMsg^.Result and DLGC_WANTCHARS <> 0 then
                Include(DlgCodes, dcWantChars);
              if PMsg^.Result and DLGC_BUTTON <> 0 then
                Include(DlgCodes, dcButton);

              DoGetDlgCode(DlgCodes);

              if not (dcNative in DlgCodes) then
              begin
                PMsg^.Result := 0;
                if dcWantAllKeys in DlgCodes then
                  PMsg^.Result := PMsg^.Result or DLGC_WANTALLKEYS;
                if dcWantArrows in DlgCodes then
                  PMsg^.Result := PMsg^.Result or DLGC_WANTARROWS;
                if dcWantTab in DlgCodes then
                  PMsg^.Result := PMsg^.Result or DLGC_WANTTAB;
                if dcWantChars in DlgCodes then
                  PMsg^.Result := PMsg^.Result or DLGC_WANTCHARS;
                if dcButton in DlgCodes then
                  PMsg^.Result := PMsg^.Result or DLGC_BUTTON;
              end;
            end;

            WM_SETFOCUS:
              begin
                with PMsg^ do
                  Result := InheritMsg(Instance, Msg, WParam, LParam);
                DoSetFocus(HWND(PMsg^.WParam));
              end;
            WM_KILLFOCUS:
              begin
                with PMsg^ do
                  Result := InheritMsg(Instance, Msg, WParam, LParam);
                DoKillFocus(HWND(PMsg^.WParam));
              end;
        else
          CallInherited := True;
        end;
    end;
  end;

  if CallInherited then
    with PMsg^ do
      Result := InheritMsg(Instance, Msg, WParam, LParam);
end;

{ VCL sends CM_CONTROLLISTCHANGE and CM_CONTROLCHANGE in an other order that
  the CLX methods are used. So we must correct it by evaluating "Inserting". } 
procedure Control_ControlsListChanging(Instance: TControl; Control: TControl;
  Inserting: Boolean);
begin
  if Inserting then
    InheritMsg(Instance, CM_CONTROLLISTCHANGE, Integer(Control), Integer(Inserting))
  else
    InheritMsg(Instance, CM_CONTROLCHANGE, Integer(Control), Integer(Inserting))
end;

procedure Control_ControlsListChanged(Instance: TControl; Control: TControl;
  Inserting: Boolean);
begin
  if not Inserting then
    InheritMsg(Instance, CM_CONTROLLISTCHANGE, Integer(Control), Integer(Inserting))
  else
    InheritMsg(Instance, CM_CONTROLCHANGE, Integer(Control), Integer(Inserting))
end;

{$ENDIF VCL}

{$IFDEF VisualCLX}

type
  TOpenWidgetControl = class(TWidgetControl);

  TWidgetControlPainting = class(TInterfacedObject)
  private
    FCanvas: TCanvas;
    FInstance: TWidgetControl;
  public
    constructor Create(Instance: TWidgetControl; Canvas: TCanvas;
      EventRegion: QRegionH);
    destructor Destroy; override;
  end;

constructor TWidgetControlPainting.Create(Instance: TWidgetControl; Canvas: TCanvas;
  EventRegion: QRegionH);
begin
  inherited Create;
  FCanvas := Canvas;
  FInstance := Instance;

  TControlCanvas(FCanvas).StartPaint;
  QPainter_setClipRegion(FCanvas.Handle, EventRegion);
end;

destructor TWidgetControlPainting.Destroy;
begin
  TControlCanvas(FCanvas).StopPaint;
  inherited Destroy;
end;

function WidgetControl_Painting(Instance: TWidgetControl; Canvas: TCanvas;
  EventRegion: QRegionH): IInterface;
begin
  if csDestroying in Instance.ComponentState then
    Result := nil
  else
    Result := TWidgetControlPainting.Create(Instance, Canvas, EventRegion);
end;

procedure WidgetControl_DefaultPaint(Instance: TWidgetControl; Canvas: TCanvas);
var
  PaintDevice: QPaintDeviceH;
  IsActive: Boolean;
  Painting: procedure(Instance: TWidgetControl; Sender: QObjectH; EventRegion: QRegionH);
begin
  if not (csDestroying in Instance.ComponentState) and
     (not Supports(Instance, IJvCustomControlEvents)) then
       { TCustomControls do not have a default paint method. }
  begin
   // Canvas.StopPaint uses a counter, but we must garantee the Stop.
    PaintDevice := nil;
    IsActive := QPainter_isActive(Canvas.Handle);
    if IsActive then
    begin
      PaintDevice := QPainter_device(Canvas.Handle);
      QPainter_end(Canvas.Handle);
    end;
    try
      Painting := @TOpenWidgetControl.Painting;
     // default painting 
      Painting(Instance, Instance.Handle, QPainter_clipRegion(Canvas.Handle));
    finally
      // restore
      if IsActive then
        QPainter_begin(Canvas.Handle, PaintDevice); // restart
    end;
  end;
end;

function TWidgetControl_NeedKey(Instance: TWidgetControl; Key: Integer;
  Shift: TShiftState; const KeyText: WideString; InheritedValue: Boolean): Boolean;

  function IsTabKey: Boolean;
  begin
    Result := (Key = Key_Tab) or (Key = Key_BackTab);
  end;

  function IsArrowKey: Boolean;
  begin
    Result := (Key = Key_Left) or (Key = Key_Right) or
              (Key = Key_Down) or (Key = Key_Up);
  end;

var
  DlgCodes: TDlgCodes;
  Value: TInputKeys;
begin
  Result := InheritedValue;
  Value := TOpenWidgetControl(Instance).InputKeys;

  DlgCodes := [dcNative];
  if ikAll in Value then
    Include(DlgCodes, dcWantAllKeys);
  if ikArrows in Value then
    Include(DlgCodes, dcWantArrows);
  if ikTabs in Value then
    Include(DlgCodes, dcWantTab);
  if ikChars in Value then
    Include(DlgCodes, dcWantChars);

  (Instance as IJvWinControlEvents).DoGetDlgCode(DlgCodes);

  if not (dcNative in DlgCodes) then
  begin
    Result := False;
    if dcWantAllKeys in DlgCodes then
      Result := True;
    if (not Result) and (dcWantTab in DlgCodes) then
      Result := IsTabKey;
    if (not Result) and (dcWantArrows in DlgCodes) then
      Result := IsArrowKey;
    if (not Result) and (dcWantChars in DlgCodes) then
      Result := ((Shift * [ssCtrl, ssAlt] = []) and
                ((Hi(Word(Key)) = 0) or (Length(KeyText) > 0))) and
                not (IsTabKey or IsArrowKey);
  end;
end;

{$ENDIF VisualCLX}

// *****************************************************************************

JV_CONTROL_EVENTS_IMPL(Control)
JV_WINCONTROL_EVENTS_IMPL(WinControl)

JV_CONTROL_EVENTS_IMPL_BEGIN(GraphicControl)
{$IFDEF VisualCLX}
function TJvExGraphicControl.GetText: TCaption;
begin
  Result := FText;
end;

procedure TJvExGraphicControl.SetText(const Value: TCaption);
begin
  if Value <> FText then
  begin
    FText := Value;
    TextChanged;
  end;
end;
{$ENDIF VisualCLX}
JV_CONTROL_EVENTS_IMPL_END(GraphicControl)

JV_CUSTOMCONTROL_EVENTS_IMPL(CustomControl)
JV_CUSTOMCONTROL_EVENTS_IMPL(HintWindow)

// *****************************************************************************

type
  TOpenControl = class(TControl);
  PBoolean = ^Boolean;
  PPointer = ^Pointer;

function ReadProtectedMemory(Address: Pointer; var Buffer; Count: Cardinal): Boolean;
var
  n: Cardinal;
begin
  Result := ReadProcessMemory(GetCurrentProcess, Address, @Buffer, Count, n);
  Result := Result and (n = Count);
end;

function WriteProtectedMemory(Address: Pointer; const Buffer; Count: Cardinal): Boolean;
var
  n: Cardinal;
begin
  Result := WriteProcessMemory(GetCurrentProcess, Address, @Buffer, Count, n);
  Result := Result and (n = Count);
end;

type
  TJumpCode = packed record
    Pop: Byte; // pop xxx
    Jmp: Byte; // jmp Offset
    Offset: Integer;
  end;

  TOrgCallCode = packed record
    Push: Byte; // push ebx/ebp
    InjectedCode: TJumpCode;
    Jmp: Byte; // jmp Offset
    Offset: Integer;
    Address: Pointer;
  end;

function GetRelocAddress(ProcAddress: Pointer): Pointer;
type
  TRelocationRec = packed record
    Jump: Word;
    Address: PPointer;
  end;
var
  Relocation: TRelocationRec;
  Data: Byte;
begin
  Result := ProcAddress;
 // the relocation table meight be protected
  if ReadProtectedMemory(ProcAddress, Data, SizeOf(Data)) then
  begin
    if Data = $FF then // ProcAddress is in a dll or package
      if ReadProtectedMemory(ProcAddress, Relocation, SizeOf(Relocation)) then
        Result := Relocation.Address^;
  end;
end;

function InstallProcHook(ProcAddress, HookProc, OrgCallProc: Pointer): Boolean;
var
  Code: TJumpCode;
  OrgCallCode: TOrgCallCode;
begin
  ProcAddress := GetRelocAddress(ProcAddress);
  Result := False;
  if Assigned(ProcAddress) and Assigned(HookProc) then
  begin
    if OrgCallProc <> nil then
    begin
      if ReadProtectedMemory(ProcAddress, OrgCallCode, SizeOf(OrgCallCode) - (1 + SizeOf(Integer))) then
      begin
        OrgCallCode.Jmp := $E9;
        OrgCallCode.Offset := (Integer(ProcAddress) + 1 + SizeOf(Code)) -
          Integer(OrgCallProc) -
          (SizeOf(OrgCallCode) - SizeOf(OrgCallCode.Address));
        OrgCallCode.Address := ProcAddress;

        WriteProtectedMemory(OrgCallProc, OrgCallCode, SizeOf(OrgCallCode));
        FlushInstructionCache(GetCurrentProcess, OrgCallProc, SizeOf(OrgCallCode));
      end;
    end;

    if PByte(ProcAddress)^ = $53 then // push ebx
      Code.Pop := $5B // pop ebx
    else
    if PByte(ProcAddress)^ = $55 then // push ebp
      Code.Pop := $5D // pop ebp
    else
      Exit;
    Code.Jmp := $E9;
    Code.Offset := Integer(HookProc) - (Integer(ProcAddress) + 1) - SizeOf(Code);

   { The strange thing is that something overwrites the $e9 with a "PUSH xxx" }
    if WriteProtectedMemory(Pointer(Cardinal(ProcAddress) + 1), Code,
         SizeOf(Code)) then
    begin
      FlushInstructionCache(GetCurrentProcess, ProcAddress, SizeOf(Code));
      Result := True;
    end;
  end;
end;

function UninstallProcHook(OrgCallProc: Pointer): Boolean;
var
  OrgCallCode: TOrgCallCode;
  ProcAddress: Pointer;
begin
  Result := False;
  if Assigned(OrgCallProc) then
  begin
    if OrgCallProc <> nil then
    begin
      if ReadProtectedMemory(OrgCallProc, OrgCallCode, SizeOf(OrgCallCode)) then
      begin
        ProcAddress := OrgCallCode.Address;

        Result := WriteProtectedMemory(ProcAddress, OrgCallCode, 1 + SizeOf(TJumpCode));
        FlushInstructionCache(GetCurrentProcess, ProcAddress, SizeOf(OrgCallCode));
      end;
    end;
  end;
end;

{$IFNDEF COMPILER6_UP}
var
  AutoSizeOffset: Cardinal;
  TControl_SetAutoSize: Pointer;

procedure OrgSetAutoSize(Instance: TControl; Value: Boolean);
asm
  dd    0, 0, 0, 0  // 16 Bytes
end;

procedure TOpenControl_SetAutoSize(Instance: TControl; Value: Boolean);
begin
  with TOpenControl(Instance) do
  begin
    if AutoSize <> Value then
    begin
      PBoolean(Cardinal(Instance) + AutoSizeOffset)^ := Value;
      if Value then
        AdjustSize;
    end;
  end;
  // same as OrgSetAutoSize(Instance, Value); but secure
end;

procedure SetAutoSizeHook(Instance: TControl; Value: Boolean);
var
  IntfControl: IJvControlEvents;
begin
  if Instance.GetInterface(IJvControlEvents, IntfControl) then
    IntfControl.SetAutoSize(Value)
  else
    TOpenControl_SetAutoSize(Instance, Value);
end;

{$OPTIMIZATION ON} // be sure to have optimization activated
function GetCode(Instance: TOpenControl): Boolean; register;
begin
  { generated code:
      8A40xx       mov al,[eax+Byte(Offset)]
  }
  Result := Instance.AutoSize;
end;

procedure SetCode(Instance: TOpenControl); register;
begin
  { generated code:
      B201         mov dl,$01
      E8xxxxxxxx   call TControl.SetAutoSize
  }
  Instance.AutoSize := True;
end;

type
  PGetCodeRec = ^TGetCodeRec;
  TGetCodeRec = packed record
    Sign: Word; // $408a   bytes swapped
    Offset: Byte;
  end;

type
  PSetCodeRec = ^TSetCodeRec;
  TSetCodeRec = packed record
    Sign1: Word; // $01b2  bytes swapped
    Sign2: Byte; // $e8
    Offset: Integer;
  end;

const
  GetCodeSign = $408a;
  SetCodeSign1 = $01b2;
  SetCodeSign2 = $e8;

procedure InitHookVars;
var
  PGetCode: PGetCodeRec;
  PSetCode: PSetCodeRec;
begin
  TControl_SetAutoSize := nil;
  AutoSizeOffset := 0;

  PGetCode := @GetCode;
  PSetCode := @SetCode;

  if (PGetCode^.Sign = GetCodeSign) and
     (PSetCode^.Sign1 = SetCodeSign1) and (PSetCode^.Sign2 = SetCodeSign2) then
  begin
    AutoSizeOffset := PGetCode^.Offset;
    TControl_SetAutoSize := GetRelocAddress(
      Pointer(Integer(@SetCode) + SizeOf(TSetCodeRec) + PSetCode^.Offset)
    );
  end;
end;

initialization
  InitHookVars;
  InstallProcHook(TControl_SetAutoSize, @SetAutoSizeHook, @OrgSetAutoSize);

finalization
  UninstallProcHook(@OrgSetAutoSize);

{$ENDIF !COMPILER6_UP}

{$IFDEF VisualCLX}

// Handles DoSetFocus and DoKillFocus

function AppEventFilter(App: TApplication; Sender: QObjectH; Event: QEventH): Boolean; cdecl;
var
  Control: TWidgetControl;
  Intf: IJvWinControlEvents;
  Wnd: HWND;
begin
  Result := False; // let the default event handler handle this event
  try
    case QEvent_type(Event) of
      QEventType_FocusIn, QEventType_FocusOut:
        begin
          Control := FindControl(QWidgetH(Sender));
          if (Control <> nil) and Supports(Control, IJvWinControlEvents, Intf) then
          begin
            if Screen.ActiveControl <> nil then
              Wnd := Screen.ActiveControl.Handle
            else
              Wnd := HWND(0);
            if QEvent_type(Event) = QEventType_FocusIn then
              Intf.DoSetFocus(Wnd)
            else
              Intf.DoKillFocus(Wnd);
          end;
        end;
    end;
  except
    on E: Exception do
    begin
      Application.ShowException(E);
      Result := False;
    end;
  end;
end;

var
  AppEventFilterHook: QObject_hookH = nil;

procedure InstallAppEventFilterHook;
var
  Method: TMethod;
begin
  if AppEventFilterHook = nil then
  begin
    Method.Code := @AppEventFilter;
    Method.Data := Application;
    AppEventFilterHook := QObject_hook_create(Application.Handle);
    Qt_hook_hook_events(AppEventFilterHook, Method);
  end;
end;

procedure UninstallAppEventFilterHook;
begin
  if Assigned(AppEventFilterHook) then
    QObject_hook_destroy(AppEventFilterHook);
end;


function CallSetFocusedControl(Instance: TCustomForm; Control: TWidgetControl): Boolean;
asm
  dd    0, 0, 0, 0  // 16 Bytes
end;

function SetFocusedControlHook(Instance: TCustomForm; Control: TWidgetControl): Boolean;
var
  Msg: TCMFocusChanged;
begin
  if csFocusing in Instance.ControlState then
    Result := CallSetFocusedControl(Instance, Control)
  else
  begin
    Result := CallSetFocusedControl(Instance, Control);
    if Result then
    begin
      Instance.ControlState := Instance.ControlState + [csFocusing]; // lock
      try
        Msg.Msg := CM_FOCUSCHANGED;
        Msg.Unused := 0;
        Msg.Sender := Control;
        Msg.Result := 0;
        Instance.Broadcast(Msg);
      finally
        Instance.ControlState := Instance.ControlState - [csFocusing];
      end;
    end;
  end;
end;

initialization
  InstallAppEventFilterHook;
  InstallProcHook(@TCustomForm.SetFocusedControl, @SetFocusedControlHook,
                  @CallSetFocusedControl);

finalization
  UninstallProcHook(@CallSetFocusedControl);
  UninstallAppEventFilterHook;

{$ENDIF VisualCLX}

end.
