import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../party/net/firebase_party_transport.dart';
import '../party/net/party_net.dart';
import '../party/party_controller.dart';
import '../party/party_models.dart';

/// LIVE 5-player lockstep check against the REAL hot-potato-games RTDB.
///
/// Not part of the app. Run explicitly:
///
///   flutter run -d chrome -t lib/dev/party_live_check.dart
///
/// Spins up one host + four joiners (synthetic uids, one anonymous auth — the
/// cell_games rules grant any authed user write access to a room), plays a
/// full 1-round ffa5 match through the real transport, and prints
/// `PARTY-LIVE-RESULT: PASS/FAIL` to the console. This verifies what the
/// in-memory tests can't: anonymous auth, RTDB rules, real async listener
/// ordering, and lockstep convergence over the production pipe.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text('party live check — watch the console',
            style: TextStyle(color: Colors.white54)),
      ),
    ),
  ));
  _run();
}

Future<void> _run() async {
  PartyNet? hostNet;
  String? code;
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuth.instance.signInAnonymously();
    debugPrint('PARTY-LIVE: authed anonymously');

    code = _roomCode();
    final uids = List.generate(5, (i) => 'live-check-$code-u$i');
    debugPrint('PARTY-LIVE: room $code');

    hostNet = await PartyNet.host(
      transport: FirebasePartyTransport(),
      gameId: code,
      uid: uids[0],
      name: 'Host',
      mode: PartyMode.ffa5,
      rounds: 1,
    );
    final nets = <PartyNet>[hostNet];
    for (var i = 1; i < 5; i++) {
      nets.add(await PartyNet.join(
        transport: FirebasePartyTransport(),
        gameId: code,
        uid: uids[i],
        name: 'P$i',
      ));
    }

    await _until(() => nets.every((n) => n.players.length == 5),
        'roster 5/5 on every client');
    debugPrint('PARTY-LIVE: roster 5/5 on all 5 clients');

    await nets.first.startGame();
    await _until(() => nets.every((n) => n.controller != null),
        'all client replicas built');
    debugPrint('PARTY-LIVE: match started, replicas live');

    // Drive the match through the real pipe: act, then wait for the host's
    // canonical publication to move the authoritative controller forward.
    final c = nets.first.controller!;
    var safety = 0;
    while (c.phase != PartyPhase.gameOver && safety++ < 500) {
      final phase = c.phase;
      final logLen = c.inputLog.length;
      final cur = c.currentPlayerIndex;
      switch (phase) {
        case PartyPhase.turnStart:
          nets[cur].act(PartyInputKind.roll);
          break;
        case PartyPhase.rollResult:
          nets[cur].act(PartyInputKind.beginWalk);
          break;
        case PartyPhase.chooseBranch:
          nets[cur].act(PartyInputKind.choosePath,
              value: c.branchOptions.first);
          break;
        case PartyPhase.shopOffer:
          nets[cur].act(PartyInputKind.skipPotato);
          break;
        case PartyPhase.cardDecision:
          nets[cur].act(PartyInputKind.chooseCardOption, value: 0);
          break;
        case PartyPhase.minigamePlaying:
        case PartyPhase.passPhone:
          var s = 0;
          while (s < 5 && c.hasSubmittedMiniScore(s)) {
            s++;
          }
          if (s >= 5) break; // scored round settling
          nets[s].act(PartyInputKind.miniScore, value: 100 + 10 * s);
          break;
        default:
          break; // deterministic phase — the host settles it
      }
      await _until(() => c.inputLog.length > logLen || c.phase != phase,
          'progress past $phase (input ${logLen + 1})');
    }
    if (c.phase != PartyPhase.gameOver) {
      throw StateError('match never reached gameOver ($safety actions)');
    }
    debugPrint('PARTY-LIVE: host reached gameOver after $safety actions');

    await _until(
        () => nets.every((n) => n.controller!.phase == PartyPhase.gameOver),
        'every client reaches gameOver');
    final host = nets.first.controller!;
    for (var k = 1; k < nets.length; k++) {
      final client = nets[k].controller!;
      for (var i = 0; i < host.players.length; i++) {
        final a = host.players[i], b = client.players[i];
        if (b.position != a.position ||
            b.diamonds != a.diamonds ||
            b.potatoes != a.potatoes) {
          throw StateError('client $k diverged on player $i: '
              'pos ${b.position}/${a.position} 💎${b.diamonds}/${a.diamonds} '
              '🥔${b.potatoes}/${a.potatoes}');
        }
      }
    }
    final ranking = host.finalPlayerRanking;
    debugPrint('PARTY-LIVE: winner ${ranking.first.name} '
        '(🥔${ranking.first.potatoes} 💎${ranking.first.diamonds})');
    debugPrint('PARTY-LIVE-RESULT: PASS — 5-player online match completed and '
        'converged on all clients (room $code)');
  } catch (e, st) {
    debugPrint('PARTY-LIVE-RESULT: FAIL — $e');
    debugPrint('$st');
  } finally {
    // Leave no trace in prod RTDB.
    if (hostNet != null && code != null) {
      try {
        await hostNet.transport.removeGame(code);
        debugPrint('PARTY-LIVE: room $code cleaned up');
      } catch (_) {}
    }
  }
}

Future<void> _until(bool Function() cond, String what) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (!cond()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('timed out waiting for: $what');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

String _roomCode() {
  const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  final rng = Random();
  return 'Z${List.generate(3, (_) => letters[rng.nextInt(letters.length)]).join()}';
}
