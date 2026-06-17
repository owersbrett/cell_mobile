import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';

/// Lifecycle of one mini-game run, driven by [MiniGameHost].
enum MiniGamePhase { intro, countdown, playing, finished }

/// Shared state for a single run of a mini-game.
///
/// The host owns the clock: it starts the run, ticks the remaining time and
/// ends the run. Game widgets read [isRunning] / [remaining], and report
/// points through [addScore]. A game may end itself early with [endEarly]
/// (e.g. a sudden-death fail state) — the score it has at that moment stands.
class MiniGameSession extends ChangeNotifier {
  MiniGameSession({required this.spec, this.playerLabel});

  final MiniGameSpec spec;

  /// Shown during intro/results in party mode ("Tater — Team Red"). Null in solo.
  final String? playerLabel;

  MiniGamePhase _phase = MiniGamePhase.intro;
  int _score = 0;
  Duration _remaining = Duration.zero;
  Duration _bonusTime = Duration.zero;

  MiniGamePhase get phase => _phase;
  int get score => _score;
  Duration get remaining => _remaining;
  Duration get bonusTime => _bonusTime;
  bool get isRunning => _phase == MiniGamePhase.playing;

  void addScore(int delta) {
    if (!isRunning) return;
    _score = (_score + delta).clamp(0, 1 << 31);
    notifyListeners();
  }

  void addTime(Duration d) {
    if (!isRunning) return;
    _bonusTime += d;
    notifyListeners();
  }

  /// Game-initiated early finish (fail states, perfect clears).
  void endEarly() {
    if (!isRunning) return;
    _setPhase(MiniGamePhase.finished);
  }

  // Host-side controls.
  void hostSetPhase(MiniGamePhase phase) => _setPhase(phase);

  void hostTick(Duration remaining) {
    _remaining = remaining;
    notifyListeners();
  }

  void hostReset() {
    _score = 0;
    _remaining = Duration(seconds: spec.durationSeconds);
    _bonusTime = Duration.zero;
    _setPhase(MiniGamePhase.intro);
  }

  void _setPhase(MiniGamePhase phase) {
    if (_phase == phase) return;
    _phase = phase;
    notifyListeners();
  }
}

typedef MiniGameBuilder = Widget Function(
    BuildContext context, MiniGameSession session);

/// Declarative description of a mini-game: identity, rules, scoring and the
/// widget that plays it. One spec serves both Explore (solo score attack)
/// and Party mode (pass-and-play, highest score wins the round).
class MiniGameSpec {
  final String id;
  final String name;
  final BioScale scale;

  /// One-line hook shown under the name ("Ignite matter from the void").
  final String tagline;

  /// Short imperative rules, one action each ("Tap blue sparks: +10").
  final List<String> rules;

  /// One line that makes winning unambiguous ("Most matter when time runs out wins").
  final String howToWin;

  final int durationSeconds;

  /// What the score counts ("matter", "collisions", "molecules").
  final String scoreUnit;

  /// Only enabled games appear in party mode rotation and the new explore flow.
  final bool enabled;

  final Color accent;
  final IconData icon;
  final MiniGameBuilder builder;

  const MiniGameSpec({
    required this.id,
    required this.name,
    required this.scale,
    required this.tagline,
    required this.rules,
    required this.howToWin,
    required this.durationSeconds,
    required this.scoreUnit,
    required this.enabled,
    required this.accent,
    required this.icon,
    required this.builder,
  });
}
