unit mnePASClasses;

{$mode objfpc}{$H+}
{**
 * Mini Edit
 *
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}

interface

uses
  Messages, Forms, SysUtils, StrUtils, Variants, Classes, Controls, Graphics, Contnrs,
  LCLintf, LCLType,
  Dialogs, EditorOptions, SynEditHighlighter, SynEditSearch, SynEdit,
  Registry, EditorEngine, mnXMLRttiProfile, mnXMLUtils,
  SynEditTypes, SynCompletion, SynHighlighterHashEntries, EditorProfiles,
  SynHighlighterPas, SynHighlighterLFM;

type
  { TPASFile }

  TPASFile = class(TEditorFile)
  protected
    procedure NewSource; override;
  public
  end;

  TLFMFile = class(TEditorFile)
  protected
    //procedure NewSource; override;
  public
  end;

  { TPASFileCategory }

  TPASFileCategory = class(TFileCategory)
  private
  protected
    function CreateHighlighter: TSynCustomHighlighter; override;
  public
  end;

  { TLFMFileCategory }

  TLFMFileCategory = class(TFileCategory)
  private
  protected
    function CreateHighlighter: TSynCustomHighlighter; override;
  public
  end;

  { TPascalPerspective }

  TPascalPerspective = class(TEditorPerspective)
  protected
    procedure Init; override;
  public
  end;

implementation

uses
  IniFiles, mnXMLStreams, mnUtils;

{ TLFMFileCategory }

function TLFMFileCategory.CreateHighlighter: TSynCustomHighlighter;
begin
  Result := TSynLFMSyn.Create(nil);
end;

{ TPascalPerspective }

procedure TPascalPerspective.Init;
begin
  FName := 'Pascal';
  FTitle := 'Pascal project';
  FDescription := 'Pascal/FPC/Lazarus Files, *.pas, *.pp *.inc';
  FImageIndex := -1;
  AddGroup('pas', 'pas');
  AddGroup('dpr', 'pas');
  AddGroup('lpr', 'pas');
  AddGroup('ppr', 'pas');
  AddGroup('lfm', 'lfm');
  //AddGroup('inc');
end;

{ TPASFileCategory }

function TPASFileCategory.CreateHighlighter: TSynCustomHighlighter;
begin
  Result := TSynPASSyn.Create(nil);
end;

{ TPASFile }

procedure TPASFile.NewSource;
begin
  inherited NewSource;
  SynEdit.Text := 'unit ';
  SynEdit.Lines.Add('');
  SynEdit.Lines.Add('interface');
  SynEdit.Lines.Add('');
  SynEdit.Lines.Add('uses');
  SynEdit.Lines.Add('  SysUtils;');
  SynEdit.Lines.Add('');
  SynEdit.Lines.Add('implementation');
  SynEdit.Lines.Add('');
  SynEdit.Lines.Add('end.');
  SynEdit.CaretY := 1;
  SynEdit.CaretX := 5;
end;

initialization
  with Engine do
  begin
    Categories.Add('pas', TPASFile, TPASFileCategory);
    Categories.Add('lfm', TLFMFile, TLFMFileCategory);
    Groups.Add('ppr', 'Pascal Project Files', 'pas', ['ppr'], [fgkExecutable, fgkMember, fgkBrowsable]);//PPR meant Pascal project
    Groups.Add('lpr', 'Lazarus Project Files', 'pas', ['lpr'], [fgkExecutable, fgkMember, fgkBrowsable]);
    Groups.Add('dpr', 'Delphi Project Files', 'pas', ['dpr'], [fgkExecutable, fgkMember, fgkBrowsable]);
    Groups.Add('pas', 'Pascal Files', 'pas', ['pas', 'pp', 'p', 'inc'], [fgkExecutable, fgkMember, fgkBrowsable]);
    Groups.Add('lfm', 'Lazarus Form Files', 'lfm', ['lfm'], [fgkMember, fgkBrowsable]);

    Perspectives.Add(TPascalPerspective);
  end;
end.
