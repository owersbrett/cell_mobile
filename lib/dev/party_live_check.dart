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

/// LIVE 4-player lockstep check against the REAL hot-potato-games RTDB.
///
/// Not part of the app. Run explicitly:
///
///   flutter run -d chrome -t lib/dev/party_live_check.dart
///
/// Spins up one host + three joiners (host = the real anonymous auth uid —
/// required since the 2026-07-12 host-scoped cell_games rules; joiners are
/// synthetic uids riding the host's room-wide write grant), plays a
/// full 1-round ffa4 match through the real transport, and prints
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
    // Since the 2026-07-12 rules tightening, room creation requires
    // meta.host === auth.uid, so the host MUST be the real anonymous user.
    // The three joiners keep synthetic uids: every write here rides the same
    // authed connection, and the host's room-wide grant covers them. (This
    // means the harness verifies transport/lockstep, NOT the non-host
    // permission boundary — that needs a second real device/auth.)
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final uids = [myUid, ...List.generate(3, (i) => 'live-check-$code-u${i + 1}')];
    debugPrint('PARTY-LIVE: room $code');

    hostNet = await PartyNet.host(
      transport: FirebasePartyTransport(),
      gameId: code,
      uid: uids[0],
      name: 'Host',
      mode: PartyMode.ffa4,
      rounds: 1,
    );
    final nets = <PartyNet>[hostNet];
    for (var i = 1; i < 4; i++) {
      nets.add(await PartyNet.join(
        transport: FirebasePartyTransport(),
        gameId: code,
        uid: uids[i],
        name: 'P$i',
      ));
    }

    await _until(() => nets.every((n) => n.players.length == 4),
        'roster 4/4 on every client');
    debugPrint('PARTY-LIVE: roster 4/4 on all 4 clients');

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
        case PartyPhase.wheelSpin:
          // Post-build-17 phase: each spinner in queue order hits STOP.
          // value omitted ⇒ 0 ⇒ tape-draw fallback (deterministic).
          nets[c.wheel!.currentSpinner].act(PartyInputKind.wheelStop);
          break;
        case PartyPhase.moving:
          // Build-24: walks are paced locally by the board UI's ticker.
          // Headless: fast-forward the HOST's authoritative walk only —
          // it records the tape. Replicas must NOT self-pace here (they'd
          // consume draws the host hasn't published: "tape starved");
          // they converge via applyNetworkInput's own moving fast-forward
          // when the next canonical lands.
          while (c.phase == PartyPhase.moving) {
            c.advanceStep();
          }
          break;
        case PartyPhase.spaceResolved:
          nets[cur].act(PartyInputKind.confirmSpace); // walker: COMPLETE TURN
          break;
        case PartyPhase.minigameIntro:
          // Host paces the reveal (auto-dwell is a UI-layer timer).
          nets.first.act(PartyInputKind.beginMiniGame);
          break;
        case PartyPhase.minigameResults:
          nets.first.act(PartyInputKind.confirmResults);
          break;
        case PartyPhase.orderRoll:
          // THE OPENING ORDER (ORDER_AND_SOLO_SPEC §3): each pending seat
          // throws over the wire; the host taps out of the resolved reveal.
          if (c.orderResolved) {
            nets.first.act(PartyInputKind.beginMatch);
          } else {
            nets[c.orderPendingSeat!].act(PartyInputKind.orderRoll);
          }
          break;
        case PartyPhase.minigamePlaying:
        case PartyPhase.passPhone:
          // READY CHECK first (READY_UP_SPEC.md): the host rejects scores
          // until every seat has readied over the wire.
          if (c.phase == PartyPhase.passPhone && !c.allSeatsReady) {
            var r = 0;
            while (r < 4 && c.readySeats.contains(r)) {
              r++;
            }
            nets[r].act(PartyInputKind.readyUp);
            break;
          }
          var s = 0;
          while (s < 4 && c.hasSubmittedMiniScore(s)) {
            s++;
          }
          if (s >= 4) break; // scored round settling
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
    debugPrint('PARTY-LIVE-RESULT: PASS — 4-player online match completed and '
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
