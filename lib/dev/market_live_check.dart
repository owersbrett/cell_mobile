import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../firebase_env.dart';
import '../games/financial/market_trader/market_net.dart';
import '../games/financial/market_trader/market_sim.dart';
import '../games/quick_match/quick_match_transport.dart';
import '../party/net/party_transport.dart' show NetPlayer;

/// LIVE shared-market check for Market Trader (ONLINE.md Phase 1) against the
/// REAL hot-potato-games RTDB. Not part of the app. Run explicitly:
///
///   flutter run -d chrome -t lib/dev/market_live_check.dart
///
/// One anonymous auth drives a host feed + a joiner feed in-process (like
/// party_live_check: this verifies the transport, rules and convergence, NOT
/// the non-host permission boundary — that needs a second device/auth).
/// Sequence: quick room created → host publishes the tape → joiner converges
/// → host event lands on the joiner → joiner intent (via the real `requests`
/// channel) lands on the host, attributed → tick removal halts the joiner.
/// Prints `MARKET-LIVE-RESULT: PASS/FAIL`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text('market live check — watch the console',
            style: TextStyle(color: Colors.white54)),
      ),
    ),
  ));
  _run();
}

Future<void> _run() async {
  String? code;
  Timer? driver;
  try {
    await Firebase.initializeApp(options: firebaseOptionsForCurrentEnv());
    await FirebaseAuth.instance.signInAnonymously();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    debugPrint('MARKET-LIVE: authed anonymously');

    code = _roomCode();
    debugPrint('MARKET-LIVE: room $code');

    // A real quick-match room — market writes need meta.host to exist (the
    // 2026-07-12 rules gate the room-root host grant on it).
    final transport = FirebaseQuickMatchTransport();
    await transport.createRoom(
      code,
      QuickMeta(host: uid, specId: 'market_trader', seed: 4242),
      NetPlayer(uid: uid, name: 'Host', slot: 0, color: 0xFFD4A017),
    );

    final host = HostMarketFeed(
      sim: MarketSim(seed: 4242),
      channel: FirebaseMarketChannel(code),
      myUid: uid,
    );
    final net = NetMarketFeed(
      channel: FirebaseMarketChannel(code),
      myUid: uid,
    );

    var driveHost = true;
    driver = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (driveHost) host.step(0.016);
      net.step(0.016);
    });

    // 1. The joiner converges onto the published tape.
    await _until(
        () =>
            (net.price - kMtStartingPrice).abs() > 1e-6 &&
            (net.price - host.price).abs() < 6.0,
        'joiner converged onto the host tape');
    debugPrint('MARKET-LIVE: joiner tracking host '
        '(host ${host.price.toStringAsFixed(2)} / '
        'net ${net.price.toStringAsFixed(2)})');

    // 2. A host event reaches the joiner.
    host.fireEvent(0); // Drought
    await _until(() => net.news?.headline == 'DROUGHT',
        'host Drought visible on the joiner');
    debugPrint('MARKET-LIVE: host event landed on the joiner');

    // 3. A joiner intent rides the real requests channel back to the host,
    //    applies, and comes back attributed.
    net.fireEvent(4); // Recession
    await _until(
        () => host.news?.headline == 'RECESSION' && host.news?.by == uid,
        'joiner Recession applied by the host');
    await _until(() => net.news?.headline == 'RECESSION',
        'joiner sees own event on the shared tape');
    debugPrint('MARKET-LIVE: joiner intent applied + attributed');

    // 4. Host loss ⇒ halt: stop the host and yank the tick (what its
    //    onDisconnect would do).
    driveHost = false;
    await FirebaseDatabase.instance
        .ref('cell_games/$code/market/tick')
        .remove();
    await _until(() => net.halted, 'joiner halts on tick silence',
        timeout: Duration(seconds: kMtHaltAfterSec.ceil() + 5));
    debugPrint('MARKET-LIVE: joiner halted on host loss');

    host.dispose();
    net.dispose();
    debugPrint('MARKET-LIVE-RESULT: PASS — shared market verified live '
        '(room $code)');
  } catch (e) {
    debugPrint('MARKET-LIVE-RESULT: FAIL — $e');
  } finally {
    driver?.cancel();
    if (code != null) {
      try {
        await FirebaseDatabase.instance.ref('cell_games/$code').remove();
        debugPrint('MARKET-LIVE: room $code cleaned up');
      } catch (_) {}
    }
  }
}

Future<void> _until(bool Function() cond, String what,
    {Duration timeout = const Duration(seconds: 20)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!cond()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('timed out waiting for: $what');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

String _roomCode() {
  const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // I/O excluded, like the app
  final rng = Random();
  return List.generate(4, (_) => letters[rng.nextInt(letters.length)]).join();
}
