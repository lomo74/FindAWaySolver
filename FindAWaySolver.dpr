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

program FindAWaySolver;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Game in 'Game.pas';

function GetCoords(const S: string; var R, C: Integer): Boolean;
var
  comma: Integer;
begin
  Result := False;

  comma := Pos(',', S);

  if comma = 0 then
    Exit;

  R := StrToIntDef(Trim(Copy(S, 1, comma - 1)), 0);
  C := StrToIntDef(Trim(Copy(S, comma + 1, MaxInt)), 0);

  Result := (R > 0) and (C > 0);
end;

var
  TheGame: TGame;
  Print: Boolean;
  ans: string;
  R, C: Integer;
begin
  try
    Print := (ParamCount > 0) and (SameText(ParamStr(1), '-p'));
    TheGame := TGame.Create;
    try
      repeat
        Write('Size of the board (R,C): ');
        Flush(Output);
        Readln(Input, ans);
        if Trim(ans) <> '' then begin
          if GetCoords(ans, R, C) then begin
            try
              TheGame.SetSize(R, C);
              Break;
            except
              Writeln('*** invalid size');
            end;
          end else
            Writeln('*** invalid input');
        end;
      until False;

      repeat
        Write('Obstacle at (R,C) [leave blank to exit loop]: ');
        Flush(Output);
        Readln(Input, ans);
        if Trim(ans) <> '' then begin
          if GetCoords(ans, R, C) then begin
            try
              TheGame.ObstacleAt(R - 1, C - 1);
            except
              Writeln('*** invalid coordinates');
            end;
          end else
            Writeln('*** invalid input');
        end;
      until Trim(ans) = '';

      repeat
        Write('Start at (R,C): ');
        Flush(Output);
        Readln(Input, ans);
        if Trim(ans) <> '' then begin
          if GetCoords(ans, R, C) then begin
            try
              TheGame.StartAt(R - 1, C - 1);
              Break;
            except
              Writeln('*** invalid coordinates');
            end;
          end else
            Writeln('*** invalid input');
        end;
      until False;

      Writeln;

      TheGame.PrintBoard;

      if TheGame.Solve(Print) then begin
        if not Print then
          TheGame.PrintSolution(True);

        Writeln('Total evaluated moves: ', TheGame.Moves);
      end else
        Writeln('No solution!');
    finally
      TheGame.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
