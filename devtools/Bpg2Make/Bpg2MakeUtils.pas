unit Bpg2MakeUtils;

interface

procedure Run;

implementation
uses
  Windows, Classes, SysUtils, JclStrings;

{$IFNDEF MSWINDOWS}
 {$IFNDEF LINUX}
const
  PathDelim = '\';
 {$ENDIF}
{$ENDIF}

const
  DefaultMakeFile =
    '#--------------------------------------------------------------------------------------------------#' + sLineBreak +
    '#                                                                                                  #' + sLineBreak +
    '# devtools                                                                                         #' + sLineBreak +
    '#                                                                                                  #' + sLineBreak +
    '#--------------------------------------------------------------------------------------------------#' + sLineBreak +
    '' + sLineBreak +
    '!ifndef ROOT' + sLineBreak +
    'ROOT = $(MAKEDIR)' + sLineBreak +
    '!endif' + sLineBreak +
    '#---------------------------------------------------------------------------------------------------' + sLineBreak +
{    'SRC = ..\Run' + sLineBreak +
    'ARCH = ..\Archive' + sLineBreak +
    'COM = ..\Common' + sLineBreak +
    'BIN = ..\Bin' + sLineBreak +
    'DCU = ..\Dcu' + sLineBreak +
    'JCL = ..\..\..\JCL\source' + sLineBreak +
    'DRC = $&.drc' + sLineBreak +
    'SRCP = $(SRC);$(COM);$(JCL);$(ARCH);$(DCU)' + sLineBreak +
    'SRCH = ..\$(SRC);..\$(COM);..\$(JCL);..\$(ARCH);..\$(DCU)' + sLineBreak +}
    '#---------------------------------------------------------------------------------------------------' + sLineBreak +
    'MAKE = $(ROOT)\make.exe -$(MAKEFLAGS) -f$**' + sLineBreak +
    'DCC  = $(ROOT)\dcc32.exe -Q -W -H -M -$O+ $**' + sLineBreak +
//    'DCC  = $(ROOT)\dcc32.exe -e$(BIN) -i$(SRCP) -n$(DCU) -r$(SRCP) -u$(SRCP) -q -w -m' + sLineBreak +
    'BRCC = $(ROOT)\brcc32.exe $**' + sLineBreak +
    '#---------------------------------------------------------------------------------------------------' + sLineBreak;


procedure ShowHelp;
begin
  writeln('');
  writeln('');
  writeln('Bpg2Make: Creates a MAKEFILE from a BPG file');
  writeln('');
  writeln('Usage:');
  writeln(ExtractFilename(ParamStr(0)),' <bpgfile>');
  writeln('');
  writeln(#9'<bpgfile> - the Borland Package Group file');
end;

function GetReturnPath(const Dir: string): string;
var
  i: Integer;
begin
  Result := '';
  if Dir <> '' then
  begin
    Result := '..';
    for i := 1 to Length(Dir) do
      if Dir[i] = PathDelim then
        Result := Result + '\..';
  end;
end;

function CreateMakeFile(const Filename: string): Boolean;
var
  i, ps: Integer;
  List, MkLines, Targets: TStringlist;
  S, SourceFile, Dir: string;
  Commands, ProjectCommands : string;
begin
  Result := False;
  if not FileExists(Filename) then
  begin
    WriteLn('ERROR: ', Filename, ' not found!');
    Exit;
  end;

  List := TStringList.Create;
  MkLines := TStringList.Create;
  Targets := TStringList.Create;
  try
    List.LoadFromFile(Filename);

    MkLines.Text := DefaultMakeFile;

    i := 0;
    while i < List.Count do
    begin
      S := List[i];
      ps := Pos('bpl: ', S);
      if ps <> 0 then
      begin
        Targets.Add(Trim(Copy(S, 1, ps + 2)) + '=' + Trim(Copy(S, ps + 5, MaxInt)));
        Commands := '';
        Inc(i);
        while (i < List.Count) and (List[i] <> '') do
        begin
          Commands := Commands + List[i] + #13#10;
          Inc(i);
        end;
      end;

      if StrLIComp('PROJECTS =', PChar(S), 10) = 0 then
      begin
        s := Trim(S);
        MkLines.Add(S);
        while (i < List.Count) and (S <> '') and (S[Length(S)] = '\') do
        begin
          Inc(i);
          S := Trim(List[i]);
          MkLines.Add(#9 + S);
        end;
      end;
      Inc(i);
    end;
    MkLines.Add('#---------------------------------------------------------------------------------------------------');
    MkLines.Add('default: $(PROJECTS)');
    MkLines.Add('#---------------------------------------------------------------------------------------------------');
    MkLines.Add('');
    for i := 0 to Targets.Count - 1 do
    begin
      S := Targets[i];
      ps := Pos('=', S);
      SourceFile := Copy(S, ps + 1, MaxInt);
      SetLength(S, ps - 1);
      Dir := ExtractFileDir(SourceFile);
      MkLines.Add(S + ': ' + SourceFile);
      SourceFile := ExtractFileName(SourceFile);
      if Dir <> '' then
        MkLines.Add(#9'@cd ' + Dir);
      ProjectCommands := Commands;
      StrReplace(ProjectCommands, '$**', SourceFile, [rfReplaceAll]);
      StrReplace(ProjectCommands, '$*', Copy(SourceFile, 1, Length(SourceFile) - Length(ExtractFileExt(SourceFile))), [rfReplaceAll]);
      MkLines.Add(ProjectCommands);
      //MkLines.Add(#9'$(DCC) $&' + ExtractFileExt(SourceFile));
      if Dir <> '' then
        MkLines.Add(#9'@cd ' + GetReturnPath(Dir));
      MkLines.Add('');
    end;
    MkLines.SaveToFile(ChangeFileExt(FileName, '.mak'));
  finally
    Targets.Free;
    MkLines.Free;
    List.Free;
  end;
  Result := True;
end;

procedure Run;
begin
  {
    command-line:
      <filename>
  }
  if (ParamCount <> 1) or (LowerCase(ExtractFileExt(ParamStr(1))) <> '.bpg') then
    ShowHelp
  else
  try
    if CreateMakeFile(ExpandUNCFileName(ParamStr(1))) then
      WriteLn(' Makefile created');
  except
    on E: Exception do
      writeln('ERROR: ', E.Message);
  end;
end;

end.

