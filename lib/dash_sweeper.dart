import 'package:flutter/material.dart';

class DashSweeper extends StatefulWidget {
  final int rows;
  final int columns;

  const DashSweeper({
    super.key,
    required this.rows,
    required this.columns,
  });

  @override
  State<DashSweeper> createState() => _DashSweeperState();
}

class _DashSweeperState extends State<DashSweeper> {
  late List<Tile> tiles;

  @override
  void initState() {
    super.initState();
    _generateTiles(widget.rows, widget.columns);
  }

  void _generateTiles(int rows, int columns) {
    // calculate tiles
    final amount = rows * columns;
    final dashAmount = amount ~/ 10; // TODO customize percentage
    final emptyAmount = amount - dashAmount;

    // create tiles
    final dashTiles = List.generate(
      dashAmount,
      (_) => DashTile(TileState.idle),
    );
    final emptyTiles = List.generate(
      emptyAmount,
      (_) => EmptyTile(TileState.idle),
    );
    tiles = [...dashTiles, ...emptyTiles]..shuffle();
  }

  bool inBounds(int row, int column) {
    return row >= 0 &&
        row < widget.rows &&
        column >= 0 &&
        column < widget.columns;
  }

  int? getIndex(int row, int column) {
    if (!inBounds(row, column)) return null;
    return (row * widget.columns) + column;
  }

  (int row, int column) getPointForIndex(int index) {
    final row = (index / widget.columns).floor();
    final column = index % widget.columns;
    return (row, column);
  }

  int? topLeftIndex(int row, int column) {
    final targetRow = row - 1;
    final targetColumn = column - 1;
    return getIndex(targetRow, targetColumn);
  }

  int? topCenterIndex(int row, int column) {
    final targetRow = row - 1;
    return getIndex(targetRow, column);
  }

  int? topRightIndex(int row, int column) {
    final targetRow = row - 1;
    final targetColumn = column + 1;
    return getIndex(targetRow, targetColumn);
  }

  int? leftIndex(int row, int column) {
    final targetColumn = column - 1;
    return getIndex(row, targetColumn);
  }

  int? rightIndex(int row, int column) {
    final targetColumn = column + 1;
    return getIndex(row, targetColumn);
  }

  int? bottomLeftIndex(int row, int column) {
    final targetRow = row + 1;
    final targetColumn = column - 1;
    return getIndex(targetRow, targetColumn);
  }

  int? bottomCenterIndex(int row, int column) {
    final targetRow = row + 1;
    return getIndex(targetRow, column);
  }

  int? bottomRightIndex(int row, int column) {
    final targetRow = row + 1;
    final targetColumn = column + 1;
    return getIndex(targetRow, targetColumn);
  }

  List<int> getNeighbouringDashes(int index) {
    return getNeighbouringIndeces(
      index,
    ).where((tileIndex) => tiles[tileIndex] is DashTile).toList();
  }

  Iterable<int> getNeighbouringIndeces(int index) {
    final (row, column) = getPointForIndex(index);
    return [
      topLeftIndex(row, column),
      topCenterIndex(row, column),
      topRightIndex(row, column),
      leftIndex(row, column),
      rightIndex(row, column),
      bottomLeftIndex(row, column),
      bottomCenterIndex(row, column),
      bottomRightIndex(row, column),
    ].nonNulls;
  }

  void handleOnLongPress(int index) {
    final tile = tiles[index];

    final newState = switch (tile.state) {
      TileState.flagged => TileState.idle,
      TileState.idle => TileState.flagged,
      TileState.revealed => null,
    };

    setState(() {
      tiles[index] = tile.copyWith(state: newState);
    });
  }

  void handleOnTap(int index) {
    final tile = tiles[index];
    if (tile.state != TileState.idle) return;

    if (tile is DashTile) {
      _gameOver();
    }

    if (tile is EmptyTile) {
      final toReveal = emptyTilesToReveal(index);

      setState(() {
        tiles[index] = tile.copyWith(state: TileState.revealed);

        for (int tileIndex in toReveal) {
          tiles[tileIndex] = tiles[tileIndex].copyWith(
            state: TileState.revealed,
          );
        }
      });

      if (tiles.every(
        (tile) => tile is DashTile || tile.state == TileState.revealed,
      )) {
        _onWin();
      }
    }
  }

  void _onWin() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Hooray'),
          content: Text('You won!'),
          actions: [
            ElevatedButton(
              onPressed: () {
                _resetGame();
                Navigator.of(context).pop();
              },
              child: Text('Play again'),
            ),
          ],
        );
      },
    );
  }

  void _resetGame() {
    setState(() {
      _generateTiles(widget.rows, widget.columns);
    });
  }

  void _gameOver() {
    setState(() {
      tiles = tiles
          .map((tile) => tile.copyWith(state: TileState.revealed))
          .toList(growable: false);
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: Text('Bummer...'),
          actions: [
            OutlinedButton(
              onPressed: () {},
              child: Text('Show field'),
            ),
            ElevatedButton(
              onPressed: () {
                _resetGame();
                Navigator.of(context).pop();
              },
              child: Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  /// Recursive function to get all empty tiles to reveal at once.
  Set<int> emptyTilesToReveal(
    int index, {
    Set<int>? toReveal,
    Set<int>? checked,
  }) {
    toReveal ??= <int>{};
    checked ??= <int>{};
    toReveal.add(index);
    checked.add(index);

    final dashes = getNeighbouringDashes(index);
    if (dashes.isNotEmpty) return toReveal;

    final neighbours = getNeighbouringIndeces(index);
    if (checked.containsAll(neighbours)) return toReveal;

    final uncheckedNeighbours = neighbours.where((n) => !checked!.contains(n));
    for (int neighbour in uncheckedNeighbours) {
      emptyTilesToReveal(neighbour, toReveal: toReveal, checked: checked);
    }
    return toReveal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.columns,
        ),
        itemCount: tiles.length,
        itemBuilder: (context, index) {
          return switch (tiles[index]) {
            DashTile(:final state) => DashTileItem(
              state: state,
              onTap: () => handleOnTap(index),
              onLongPress: () => handleOnLongPress(index),
            ),
            EmptyTile(:final state) => EmptyTileItem(
              amount: getNeighbouringDashes(index).length,
              state: state,
              onTap: () => handleOnTap(index),
              onLongPress: () => handleOnLongPress(index),
            ),
          };
        },
      ),
    );
  }
}

enum TileState { idle, revealed, flagged }

sealed class Tile {
  final TileState state;

  Tile(this.state);

  Tile copyWith({
    TileState? state,
  });
}

class DashTile extends Tile {
  DashTile(super.state);

  @override
  DashTile copyWith({TileState? state}) {
    return DashTile(state ?? this.state);
  }
}

class EmptyTile extends Tile {
  EmptyTile(super.state);

  @override
  EmptyTile copyWith({TileState? state}) {
    return EmptyTile(state ?? this.state);
  }
}

class DashTileItem extends StatelessWidget {
  const DashTileItem({
    super.key,
    required this.state,
    required this.onTap,
    required this.onLongPress,
  });

  final TileState state;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return TileItem(
      state: state,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Icon(
        Icons.dangerous,
        color: Colors.red,
      ),
    );
  }
}

class EmptyTileItem extends StatelessWidget {
  const EmptyTileItem({
    super.key,
    required this.amount,
    required this.state,
    required this.onTap,
    required this.onLongPress,
  });

  final int amount;
  final TileState state;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return TileItem(
      state: state,
      onTap: onTap,
      onLongPress: onLongPress,
      child: amount == 0 ? SizedBox() : Text(amount.toString()),
    );
  }
}

class TileItem extends StatelessWidget {
  const TileItem({
    super.key,
    required this.state,
    required this.onTap,
    required this.onLongPress,
    required this.child,
  });

  final TileState state;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: state != TileState.idle ? 0 : 4,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Center(
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: switch (state) {
              TileState.idle => SizedBox(),
              TileState.revealed => child,
              TileState.flagged => Icon(
                Icons.flag,
                color: Colors.red,
              ),
            },
          ),
        ),
      ),
    );
  }
}
