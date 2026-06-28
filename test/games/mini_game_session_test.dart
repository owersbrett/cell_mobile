import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MiniGameSpec _spec() => MiniGameSpec(
      id: 'test',
      name: 'Test',
      scale: BioScale.nothings,
      tagline: 't',
      rules: const ['r'],
      howToWin: 'w',
      durationSeconds: 10,
      scoreUnit: 'pts',
      enabled: true,
      accent: const Color(0xFF000000),
      icon: Icons.star,
      builder: (_, __) => const SizedBox(),
    );

void main() {
  group('phase machine', () {
    test('starts in intro', () {
      expect(MiniGameSession(spec: _spec()).phase, MiniGamePhase.intro);
    });

    test('scoring only counts while playing', () {
      final s = MiniGameSession(spec: _spec())..hostReset();
      s.addScore(10); // intro — ignored
      expect(s.score, 0);

      s.hostSetPhase(MiniGamePhase.playing);
      s.addScore(10);
      expect(s.score, 10);
    });

    test('rapid taps after finish cannot change the score', () {
      final s = MiniGameSession(spec: _spec())..hostReset();
      s.hostSetPhase(MiniGamePhase.playing);
      s.addScore(40);
      s.hostSetPhase(MiniGamePhase.finished);

      // Simulate reflexive end-of-game tapping reaching the game.
      for (var i = 0; i < 20; i++) {
        s.addScore(10);
      }
      expect(s.score, 40, reason: 'finished phase must freeze the score');
    });

    test('score never goes negative', () {
      final s = MiniGameSession(spec: _spec())..hostReset();
      s.hostSetPhase(MiniGamePhase.playing);
      s.addScore(-100);
      expect(s.score, 0);
    });

    test('endEarly transitions to finished only from playing', () {
      final s = MiniGameSession(spec: _spec())..hostReset();
      s.endEarly(); // from intro — no-op
      expect(s.phase, MiniGamePhase.intro);

      s.hostSetPhase(MiniGamePhase.playing);
      s.endEarly();
      expect(s.phase, MiniGamePhase.finished);
    });
  });

  group('streak high-water mark', () {
    test('keeps the max reported streak while playing', () {
      final s = MiniGameSession(spec: _spec())..hostReset();
      s.hostSetPhase(MiniGamePhase.playing);
      s.noteStreak(5);
      s.noteStreak(22);
      s.noteStreak(3); // lower — ignored
      expect(s.bestStreak, 22);
    });

    test('ignores streak reports outside play', () {
      final s = MiniGameSession(spec: _spec())..hostReset();
      s.noteStreak(99); // intro
      expect(s.bestStreak, 0);
    });

    test('hostReset clears score, streak and phase', () {
      final s = MiniGameSession(spec: _spec());
      s.hostSetPhase(MiniGamePhase.playing);
      s.addScore(50);
      s.noteStreak(10);
      s.hostReset();
      expect(s.score, 0);
      expect(s.bestStreak, 0);
      expect(s.phase, MiniGamePhase.intro);
    });
  });
}
