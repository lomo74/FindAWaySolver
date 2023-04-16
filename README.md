# FindAWaySolver

FindAWaySolver is an algorithm that finds a solution for the "Find a Way" puzzle game available on Android.

## Why?

Because it could be done. Solving the puzzle quickly became boring, so I decided to solve the solver instead.

## How?

The algorithm is written in Pascal. It solves the puzzle recursively. It tries the following until the puzzle is solved or no moves are left:
- it tries one move in turn (north, east, south, west)
- if the dots are all "touched", then the puzzle is solved
- if there is more than one single "one way" path (i.e. dots that can be connected to a single other dot) then the move is bad
- if none of the preceding, then the function is called recursively
- if the call fails, then all moves after this one lead to no solution; the move is undone, and the next one is tried

## Usage

Sample usage:
```FindAWaySolver.exe -p < schemas\schema_1_111.txt```

## License

The code is released under the MIT license.
