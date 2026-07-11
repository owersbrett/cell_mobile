// The seam that lets Structure Formation run identically solo and online.
//
// The game plants the LOCAL player's seeds and, every frame, drains any RIVAL
// seeds that have arrived from the source. Solo injects [AiSeedSource] (rivals
// are bots); online injects a networked source (rivals are real players over a
// room code — see structure_net.dart). The game imports ONLY this abstraction,
// so it stays network-agnostic (CLAUDE.md: multiplayer wraps the host, never
// the game).
import 'dart:math';

/// One rival seed to apply to the shared universe: which claimant, which cell.
class RivalSeed {
  final int owner; // claimant index (never the local player)
  final int col;
  final int row;
  const RivalSeed(this.owner, this.col, this.row);
}

/// Supplies the rival claimants and their seeds for one run.
abstract class StructureSeedSource {
  /// This run's total claimants (including the local player at index 0).
  int get claimantCount;

  /// The local player's claimant index (always 0 here; kept explicit so an
  /// online source can seat the local device wherever the room put it).
  int get localOwner;

  /// Called when the LOCAL player plants a seed, so the source can broadcast it
  /// to rivals (no-op for the AI source — bots don't need our seeds).
  void onLocalSeed(int col, int row) {}

  /// Drain rival seeds that have arrived since the last call. [elapsed] is
  /// seconds into the run and [ownedByLocal] is the local player's current
  /// owned-cell count, so an AI source can pace/aim its bots. Returns the seeds
  /// to apply this frame (may be empty).
  List<RivalSeed> takeRivalSeeds(double elapsed, int ownedByLocal);

  void dispose() {}
}

/// Solo rivals: [rivalCount] bots that spread across the board and increasingly
/// contest the leader. Deterministic given [seed] so ATTRACT / tests replay.
class AiSeedSource extends StructureSeedSource {
  AiSeedSource({
    required this.cols,
    required this.rows,
    this.rivalCount = 3,
    int seed = 1,
    this.seedEverySeconds = 2.1,
  }) : _rng = Random(seed) {
    // Give each rival a home quadrant to open from, so early play reads as
    // distinct territories rather than a scramble in the middle.
    for (var r = 1; r <= rivalCount; r++) {
      final q = r - 1;
      _homeCol.add(((q % 2) == 0 ? 0.28 : 0.72));
      _homeRow.add((q < 2 ? 0.30 : 0.70));
      _next.add(0.6 + _rng.nextDouble() * seedEverySeconds);
    }
  }

  final int cols;
  final int rows;
  final int rivalCount;
  final double seedEverySeconds;
  final Random _rng;

  final List<double> _homeCol = [];
  final List<double> _homeRow = [];
  final List<double> _next = []; // next fire time per rival (seconds)

  /// Cells the local player owns, and rival-owned cells, fed back each frame so
  /// bots can aim contested strikes at the leader. Populated by the game.
  void reportOwnership(List<int> ownedCounts) {
    _ownedCounts = ownedCounts;
  }

  List<int> _ownedCounts = const [];

  @override
  int get claimantCount => 1 + rivalCount;

  @override
  int get localOwner => 0;

  @override
  List<RivalSeed> takeRivalSeeds(double elapsed, int ownedByLocal) {
    final out = <RivalSeed>[];
    for (var r = 1; r <= rivalCount; r++) {
      if (elapsed < _next[r - 1]) continue;
      _next[r - 1] = elapsed + seedEverySeconds * (0.75 + _rng.nextDouble() * 0.6);

      // As the game heats up (or if the human is clearly leading), a rival aims
      // near the leader to contest; otherwise it expands from its home quadrant.
      final contest = elapsed > 12 && _rng.nextDouble() < 0.45;
      double fc, fr;
      if (contest && _leaderIsStrong(ownedByLocal)) {
        // Poke toward the board centre-of-mass of the local player's region:
        // approximated as the human home (top-left) with jitter. Cheap + fine.
        fc = 0.30 + (_rng.nextDouble() - 0.5) * 0.5;
        fr = 0.30 + (_rng.nextDouble() - 0.5) * 0.5;
      } else {
        fc = _homeCol[r - 1] + (_rng.nextDouble() - 0.5) * 0.42;
        fr = _homeRow[r - 1] + (_rng.nextDouble() - 0.5) * 0.42;
      }
      final col = (fc * cols).round().clamp(0, cols - 1);
      final row = (fr * rows).round().clamp(0, rows - 1);
      out.add(RivalSeed(r, col, row));
    }
    return out;
  }

  bool _leaderIsStrong(int ownedByLocal) {
    if (_ownedCounts.isEmpty) return ownedByLocal > 12;
    var maxRival = 0;
    for (var i = 1; i < _ownedCounts.length; i++) {
      if (_ownedCounts[i] > maxRival) maxRival = _ownedCounts[i];
    }
    return ownedByLocal >= maxRival;
  }
}
