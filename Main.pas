unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, jpeg, Grids;

type
  TMainForm = class(TForm)
    PionRouge: TImage;
    PionBleu: TImage;
    Plateau: TImage;
    procedure Active(Sender: TObject);
    procedure GetPos(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Mesure(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

type
  TPion = record
    x, y: Integer;
    Col, Lig: Integer;
    Elem : Integer;
  end;

Const
    LargeurPlanche = 14;                             // Tableau 14 x 14 pour un plateau de 12x12 (modifiable ici)
    NbrElem = LargeurPlanche * LargeurPlanche - 1;

var
  MainForm: TMainForm;
  Flag, HumanPlay : Boolean;
  oCol, oLig : Integer;
  vBoard : array[0..NbrElem] of Integer;
  ta : array[0..7] of Integer = (-1, -1, -1, 0, 1, 1,  1,  0);
  tb : array[0..7] of Integer = (-1,  0,  1, 1, 1, 0, -1, -1);
  LBoard : Integer = LargeurPlanche;
  PRouge, PBleu : TPion;

  Function MemToBoard(x : Integer): TPoint;
  Function BoardToMem(x,y : Integer): Integer;
  Procedure Play;
  Procedure Kill;

implementation

{$R *.dfm}

//-------------------------------------------------------------------------------
procedure TMainForm.Active(Sender: TObject);
var
    i,j,x1,x2,y1,y2 : integer;
    WPlateau  : Integer;
begin
    // Initialisation de la planche
    for i := 0 to LBoard - 1 do
    Begin
        j := LBoard*i;
        vBoard[j] := -1;
        j := j + LBoard - 1;
        vBoard[j] := -1;
    end;
    for i := 0 to LBoard - 1 do vBoard[i] := -1;
    j := LBoard * LBoard - LBoard;
    for i := j to LBoard * LBoard - 1 do vBoard[i] := -1;

    PBleu.Elem :=  (((LBoard Div 2)-1) * LBoard) -1  + (LBoard div 2);
    PRouge.Elem := ((LBoard div 2) * LBoard) + (LBoard div 2);
    vBoard[PBleu.Elem] := -2;     // Identifie le pion bleu
    vBoard[PRouge.Elem] := -3;    // Identifie le pion rouge

    // Partie 'visuelle'
    WPlateau :=  (LBoard-2) * 48 + (LBoard-1);

    // 1 - Dimensionne la fenêtre
    MainForm.Width := WPlateau + 25;
    MainForm.Height := MainForm.Width + 20;

    // 2 - Dimensions de l'image
    Plateau.Width := WPlateau;
    Plateau.Height := Plateau.Width;

    With Plateau.Canvas do
    Begin
        Brush.Color := $c1e0fa;
        Pen.Color := clBlack;
        Rectangle(0, 0, Plateau.Width, Plateau.Height);
        pen.width := 1;
        pen.color := clBlack;

        y1 := 0;
        y2 := 0;
        x1 := 0;
        x2 := 0;

        for i := 0 to LBoard-1 do
        begin
          MoveTo(0,y1);
          LineTo(WPlateau,y2);

          MoveTo(x1,0);
          LineTo(x2,WPlateau);

          y1 := y1 + 49;
          y2 := y2 + 49;
          x1 := x1 + 49;
          x2 := x2 + 49;
        end;
    End;

    Flag := False;
    HumanPlay := True;

    PBleu.x := (((LBoard-2) div 2)-1) * 49 + 8; // Position de départ des pions
    PBleu.y := PBleu.x;
    PBleu.Col := (PBleu.x div 49) + 1;
    PBleu.Lig :=  (PBleu.y div 49) + 1;

    PRouge.x := ((LBoard div 2)-1) * 49 + 8;
    PRouge.y := PRouge.x;
    PRouge.Col := (PRouge.x div 49) + 1;
    PRouge.Lig :=  (PRouge.y div 49) + 1;

    PionBleu.Left := Plateau.Left+PBleu.x;
    PionBleu.Top := Plateau.Top+PBleu.y;

    PionRouge.Left := Plateau.Left+PRouge.x;
    PionRouge.Top := Plateau.Top+PRouge.y;

end;

//-------------------------------------------------------------------------------
procedure TMainForm.GetPos(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
    oCol := (X div 49) + 1;
    oLig := (Y div 49) + 1;
end;

//-------------------------------------------------------------------------------
procedure TMainForm.Mesure(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Var
    x1, y1 : Integer;
    Col, Lig : Integer;
    DestRect, SrcRect : TRect;
begin
    if HumanPlay then
    Begin
        x1 := (oCol - 1) * 49;
        y1 := (oLig - 1) * 49;
        Col := (X div 49) + 1;
        Lig := (Y div 49) + 1;
        if not Flag then
        Begin // Déplace le pion si possible
            if (Abs(PBleu.Col - oCol) < 2) AND (Abs(PBleu.Lig - oLig) < 2)  AND (vBoard[BoardToMem(Col,Lig)] = 0)then
            Begin
                PionBleu.Left := Plateau.Left+x1+8;
                PionBleu.Top := Plateau.Top+y1+8;
                Flag := true;
                // Mise à jour des infos du pion
                PBleu.Col := oCol;
                PBleu.Lig := oLig;
                vBoard[PBleu.Elem] := 0; // Libère la case
                PBleu.Elem := BoardToMem(oCol,oLig);
                vBoard[PBleu.Elem] := -2; // Interdit la case maintenant occupée
            End;
        end else
        Begin // Détruit la case
            With Plateau.Canvas do
            Begin
                Brush.Color := $ac7e2d;
                Rectangle(x1, y1, Col * 49 + 1, Lig * 49 + 1);
            End;

            vBoard[BoardToMem(Col,Lig)] := -1; // Interdit désormais la case détruite

            Flag := False;
            HumanPlay := False;

            // L'ordinateur joue
            Play;   // déplace le pion
            Kill;   // Détruit la case
            HumanPlay := True;
        end;
    end;
end;

//------------------------------------------------------------------------------------
Function MemToBoard(x: Integer): TPoint;
var
  Coord : Tpoint;
Begin
  Coord.Y := x div LBoard;
  Coord.X := x - (Coord.Y  * LBoard) ;
  Result := Coord;
End;

//------------------------------------------------------------------------------------
Function BoardToMem(x,y: Integer): Integer;
Begin
  Result := (y * LBoard) + x;
End;

//------------------------------------------------------------------------------------
Procedure Play;
Var
    i, j            : Integer;
    Valeur          : array[0..7] of Integer;
    Position        : array[0..7] of Integer;
    Solution        : array[0..7] of Integer;   // 8 solutions max
    vCase, vLib, p  : Integer;
    Best            : Integer;
    Coord           : TPoint;
Begin
    for i := 0 to 7 do Valeur[i] := 0;
    vBoard[PRouge.Elem] := 0;
    // Scrute les 8 cases autour du pion
    for i := 0 to 7  do
    Begin
        p := PRouge.Elem + (LBoard*ta[i]) + tb[i];
        Position[i] := p;
        if vBoard[p] = 0 then // Si la case est permise
        Begin
            vLib := 0;
            // Pour chacune des cases, compte les libertés
            for j := 0 to 7  do
            Begin
                vCase := p + (LBoard*ta[j]) + tb[j];
                if vBoard[vCase] = 0 then inc(vLib);
            End;
            Valeur[i] := vLib;
        End;
    End;
    // Regarder ici quelle est la case la plus forte ('Position' contient le no des 8 cases explorées, 'Valeur' contient leur degrés de liberté)
    for i := 0 to 7  do solution[i] := -1;
    j := 0 ; Best := 0;
    for i := 0 to 7  do
    Begin
        if (Valeur[i] >= Best) AND (Valeur[i] <> 0) then
        Begin
            if Valeur[i] = Best then inc(j) else j := 0;
            Solution[j] := i;
            Best := Valeur[i];
        End;
    End;

    // j+1 est l'ensemble des solutions. Si Best = 0, pas de solution, l'ordinateur a perdu !
    // 'Solution' contient l'indice des positions-solution

    if Best > 0 then  // Au moins une case
    Begin
      // S'il existe plusieurs solutions égalemnt valables, on en tire une au hasard
      Randomize;
      Best := Random(j+1);
      Coord := MemToBoard(Position[Solution[Best]]);

      PRouge.Lig := Coord.X;
      PRouge.Col := Coord.Y;
      PRouge.x := (Coord.X - 1) * 49;
      PRouge.y := (Coord.Y - 1) * 49;
      PRouge.Elem := Position[Solution[Best]];
      vBoard[PRouge.Elem] := -3;

      MainForm.PionRouge.Left := MainForm.Plateau.Left+PRouge.x+8;
      MainForm.PionRouge.Top := MainForm.Plateau.Top+PRouge.y+8;

    End
      Else ShowMessage('J''ai perdu ! ...');
End;

//------------------------------------------------------------------------------------------
Procedure Kill;
Var
    i, j            : Integer;
    Valeur          : array[0..7] of Integer;
    Position        : array[0..7] of Integer;
    Solution        : array[0..7] of Integer;   // 8 solutions possibles au maximum
    vCase, vLib, p  : Integer;
    Best            : Integer;
    Coord           : TPoint;
Begin
    for i := 0 to 7 do Valeur[i] := 0;
    vBoard[PBleu.Elem] := 0;
    // Scrute les 8 cases autour du pion
    for i := 0 to 7  do
    Begin
        p := PBleu.Elem + (LBoard*ta[i]) + tb[i];
        Position[i] := p;
        if vBoard[p] = 0 then // Si la case est permise
        Begin
            vLib := 0;
            // Pour chacune des cases, compte les libertés
            for j := 0 to 7  do
            Begin
                vCase := p + (LBoard*ta[j]) + tb[j];
                if vBoard[vCase] = 0 then inc(vLib);
            End;
            Valeur[i] := vLib;
        End;
    End;
    // Regarder ici quelle est la case la plus forte ('Position' contient le no des 8 cases explorées, 'Valeur' contient leur degrés de liberté)
    for i := 0 to 7  do solution[i] := -1;
    j := 0 ; Best := 0;
    for i := 0 to 7  do
    Begin
        if (Valeur[i] >= Best) AND (Valeur[i] <> 0) then
        Begin
            if Valeur[i] = Best then inc(j) else j := 0;
            Solution[j] := i;
            Best := Valeur[i];
        End;
    End;

    // j+1 est l'ensemble des solutions. Si Best = 0, pas de solution, l'ordinateur a perdu !
    // 'Solution' contient l'indice des positions-solution
    // if Best=0 then ShowMessage('Best = 0');

    if Best > 0 then  // Au moins une case
    Begin
      // S'il existe plusieurs solutions égalemnt valables, on en tire une au hasard
      Randomize;
      Best := Random(j+1);
      Coord := MemToBoard(Position[Solution[Best]]);

      // Détruit physiquement la case

      vBoard[PBleu.Elem] := -2;    // replace le pion
      vBoard[Position[Solution[Best]]] := -1; // Met à jour la planche

      i := (Coord.X - 1) * 49;
      j := (Coord.Y - 1) * 49;

      With MainForm.Plateau.Canvas do
      Begin
        for Best := 0 to 2 do
        Begin
            Brush.Color := $c1e0fa;
            Rectangle(i, j, i + 50, j+50);
            MainForm.Plateau.Refresh;
            Sleep(150);
            Brush.Color := $ac7e2d;
            Rectangle(i, j, i + 50, j+50);
            MainForm.Plateau.Refresh;
            Sleep(150);
        End;
      End;
    End
      Else ShowMessage('J''ai gagné ! ...');
End;

end.
