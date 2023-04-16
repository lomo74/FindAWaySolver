{
MIT License

Copyright (c) 2023 Lorenzo Monti

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

unit Game;

interface

uses System.SysUtils;

type
  TDotStatus = (dsUntouched, dsTouched, dsObstacle);
  TMove = (mNorth, mEast, mSouth, mWest);
  TConnection = record
    FSouth, FEast: Boolean;
  end;
  TMoveDelta = record
    FDeltaX, FDeltaY: Integer;
  end;

const
  Deltas: array[TMove] of TMoveDelta = (
    (FDeltaX: 0; FDeltaY: -1),
    (FDeltaX: 1; FDeltaY: 0),
    (FDeltaX: 0; FDeltaY: 1),
    (FDeltaX: -1; FDeltaY: 0)
  );

type
  TGame = class
  private
    FSizeX, FSizeY: Integer;
    FBoard: array of array of TDotStatus;
    FConnections: array of array of TConnection;
    FCurX, FCurY: Integer;
    FMoves: Integer;
    function IsSolved: Boolean;
    function PlayMove(AMove: TMove): Boolean;
    procedure UndoMove(AMove: TMove);
    procedure AllocArrays;
    function IsOneWayPath(Y, X: Integer): Boolean;
    function HasMoreThanOneWayPath: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure SetSize(Y, X: Integer);
    procedure ObstacleAt(Y, X: Integer);
    procedure StartAt(Y, X: Integer);
    function Solve(PrintMove: Boolean): Boolean;
    procedure PrintBoard;
    procedure PrintSolution(Solved: Boolean);
    property Moves: Integer read FMoves;
  end;

  EGameError = class(Exception);

implementation

{ TGame }

constructor TGame.Create;
begin
  Clear;
end;

destructor TGame.Destroy;
begin
  inherited;
end;

function TGame.HasMoreThanOneWayPath: Boolean;
var
  X, Y, cnt: Integer;
begin
  cnt := 0;

  for Y := Low(FBoard) to High(FBoard) do
    for X := Low(FBoard[Low(FBoard)]) to High(FBoard[Low(FBoard)]) do begin
      if IsOneWayPath(Y, X) then
        Inc(cnt);

      if cnt > 1 then begin
        Result := True;
        Exit;
      end;
    end;

  Result := False;
end;

procedure TGame.AllocArrays;
var
  Y: Integer;
begin
  SetLength(FBoard, FSizeY);
  SetLength(FConnections, FSizeY);

  for Y := Low(FBoard) to High(FBoard) do
    SetLength(FBoard[Y], FSizeX);

  for Y := Low(FConnections) to High(FConnections) do
    SetLength(FConnections[Y], FSizeX);
end;

procedure TGame.Clear;
var
  X, Y: Integer;
begin
  for Y := Low(FBoard) to High(FBoard) do
    for X := Low(FBoard[Low(FBoard)]) to High(FBoard[Low(FBoard)]) do
      FBoard[Y, X] := dsUntouched;

  FCurX := -1;
  FCurY := -1;

  for Y := Low(FConnections) to High(FConnections) do
    for X := Low(FConnections[Low(FConnections)]) to High(FConnections[Low(FConnections)]) do begin
      FConnections[Y, X].FSouth := False;
      FConnections[Y, X].FEast := False;
    end;

  FMoves := 0;
end;

function TGame.IsOneWayPath(Y, X: Integer): Boolean;
var
  cnt: Integer;
begin
  Result := False;

  if FBoard[Y, X] <> dsUntouched then
    Exit;

  cnt := 0;

  if (Y = Low(FBoard)) or
  (FBoard[Y - 1, X] = dsObstacle) or
  ((FBoard[Y - 1, X] = dsTouched) and ((FCurY <> Y - 1) or (FCurX <> X))) then
    Inc(cnt);

  if (Y = High(FBoard)) or
  (FBoard[Y + 1, X] = dsObstacle) or
  ((FBoard[Y + 1, X] = dsTouched) and ((FCurY <> Y + 1) or (FCurX <> X))) then
    Inc(cnt);

  if (X = Low(FBoard[Low(FBoard)])) or
  (FBoard[Y, X - 1] = dsObstacle) or
  ((FBoard[Y, X - 1] = dsTouched) and ((FCurY <> Y) or (FCurX <> X - 1))) then
    Inc(cnt);

  if (X = High(FBoard[Low(FBoard)])) or
  (FBoard[Y, X + 1] = dsObstacle) or
  ((FBoard[Y, X + 1] = dsTouched) and ((FCurY <> Y) or (FCurX <> X + 1))) then
    Inc(cnt);

  Result := (cnt >= 3);
end;

function TGame.IsSolved: Boolean;
var
  X, Y: Integer;
begin
  Result := False;

  for Y := Low(FBoard) to High(FBoard) do
    for X := Low(FBoard[Low(FBoard)]) to High(FBoard[Low(FBoard)]) do
      if (FBoard[Y, X] = dsUntouched) then
        Exit;

  Result := True;
end;

procedure TGame.ObstacleAt(Y, X: Integer);
begin
  if (Y < Low(FBoard)) or (Y > High(FBoard)) or
  (X < Low(FBoard[Low(FBoard)])) or (X > High(FBoard[Low(FBoard)])) then
    raise EGameError.Create('Bad values');

  if (X = FCurX) and (Y = FCurY) then
    raise EGameError.Create('Cannot put an obstacle at current starting position');

  FBoard[Y, X] := dsObstacle;
end;

function TGame.PlayMove(AMove: TMove): Boolean;
var
  NewX, NewY: Integer;
begin
  Result := False;

  NewX := FCurX + Deltas[AMove].FDeltaX;
  NewY := FCurY + Deltas[AMove].FDeltaY;

  if (NewY < Low(FBoard)) or (NewY > High(FBoard)) or
  (NewX < Low(FBoard[Low(FBoard)])) or (NewX > High(FBoard[Low(FBoard)])) then
    Exit;

  if FBoard[NewY, NewX] <> dsUntouched then
    Exit;

  FCurX := NewX;
  FCurY := NewY;

  FBoard[FCurY, FCurX] := dsTouched;

  case AMove of
    mNorth: FConnections[FCurY, FCurX].FSouth := True;
    mEast: FConnections[FCurY, FCurX - 1].FEast := True;
    mSouth: FConnections[FCurY - 1, FCurX].FSouth := True;
    mWest: FConnections[FCurY, FCurX].FEast := True;
  end;

  Result := True;
end;

procedure TGame.PrintBoard;
var
  X, Y: Integer;
begin
  Writeln('====GAME BOARD====');
  for Y := Low(FBoard) to High(FBoard) do begin
    for X := Low(FBoard[Low(FBoard)]) to High(FBoard[Low(FBoard)]) do begin
      case FBoard[Y, X] of
        dsTouched: Write('@  ');
        dsUntouched: Write('*  ');
        dsObstacle: Write('#  ');
      end;
    end;

    Writeln;
    Writeln;
  end;
end;

procedure TGame.PrintSolution(Solved: Boolean);
var
  X, Y: Integer;
begin
  if Solved then
    Writeln('=====SOLUTION=====')
  else
    Writeln('==================');

  for Y := Low(FBoard) to High(FBoard) do begin
    for X := Low(FBoard[Low(FBoard)]) to High(FBoard[Low(FBoard)]) do begin
      case FBoard[Y, X] of
        dsTouched: Write('@');
        dsUntouched: Write('*');
        dsObstacle: Write('#');
      end;

      if FConnections[Y, X].FEast then
        Write('--')
      else
        Write('  ');
    end;

    if Y <= High(FConnections) then begin
      Writeln;

      for X := Low(FConnections[Low(FConnections)]) to High(FConnections[Low(FConnections)]) do begin
        if FConnections[Y, X].FSouth then
          Write('|  ')
        else
          Write('   ');
      end;

      Writeln;
    end;
  end;
end;

procedure TGame.SetSize(Y, X: Integer);
begin
  FSizeX := X;
  FSizeY := Y;
  AllocArrays;
  Clear;
end;

function TGame.Solve(PrintMove: Boolean): Boolean;
var
  M: TMove;
begin
  Result := False;

  for M := Low(TMove) to High(TMove) do begin
    if PlayMove(M) then begin
      Inc(FMoves);

      Result := IsSolved;

      if PrintMove then
        PrintSolution(Result);

      if not Result then begin
        if not HasMoreThanOneWayPath then
          Result := Solve(PrintMove);

        if Result then
          Exit;

        UndoMove(M);
      end;
    end;
  end;
end;

procedure TGame.StartAt(Y, X: Integer);
begin
  if (Y < Low(FBoard)) or (Y > High(FBoard)) or
  (X < Low(FBoard[Low(FBoard)])) or (X > High(FBoard[Low(FBoard)])) then
    raise EGameError.Create('Bad values');

  if FBoard[Y, X] = dsObstacle then
    raise EGameError.Create('Cannot set starting position on an obstacle');

  if (FCurX >= 0) and (FCurY >= 0) then
    FBoard[FCurY, FCurX] := dsUntouched;

  FCurX := X;
  FCurY := Y;

  FBoard[FCurY, FCurX] := dsTouched;
end;

procedure TGame.UndoMove(AMove: TMove);
begin
  FBoard[FCurY, FCurX] := dsUntouched;

  case AMove of
    mNorth: FConnections[FCurY, FCurX].FSouth := False;
    mEast: FConnections[FCurY, FCurX - 1].FEast := False;
    mSouth: FConnections[FCurY - 1, FCurX].FSouth := False;
    mWest: FConnections[FCurY, FCurX].FEast := False;
  end;

  FCurX := FCurX - Deltas[AMove].FDeltaX;
  FCurY := FCurY - Deltas[AMove].FDeltaY;
end;

end.
