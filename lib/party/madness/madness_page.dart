import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../feedback/feedback_prompt.dart';
import '../../games/mini_game_host.dart';
import '../../games/quick_match/quick_room_scope.dart';
import '../../theme/potatuhs.dart';
import '../net/party_transport.dart' show NetPlayer;
import '../party_models.dart';
import '../screens/character_picker.dart';
import '../screens/party_dialogue.dart';
import 'madness_bars.dart';
import 'madness_dialogue.dart';
import 'madness_net.dart';
import 'madness_spin_view.dart';
import 'madness_tiebreak.dart';

/// MINIGAME MADNESS — the rapid-fire party format. No board, no dice, no
/// items: wheels pick the games, everyone plays at once, placement points
/// accrue, ceremonies punctuate. Pushed from the PARTY lobby's MADNESS tab
/// (host or join) with a live [MadnessNet]; this page owns and disposes it.
///
/// Every transition waits for a player (PARTY UX LAW): the spinner drives
/// the wheels AND the game start, and the host player advances the
/// ceremonies. Pre-game (Brett 2026-07-17): the intro gives ~15 seconds to
/// pick up the controls, then everyone lands in a ready-up lobby; once ALL
/// players are in, the round's spinner drives GO and every client launches
/// the game at the same moment — no laggards mid-race.
class MadnessPage extends StatefulWidget {
  final MadnessNet net;
  const MadnessPage({super.key, required this.net});

  @override
  State<MadnessPage> createState() => _MadnessPageState();
}

class _MadnessPageState extends State<MadnessPage> {
  /// The intro's controls-reading window before the ready lobby.
  static const int _kIntroSeconds = 15;

  MadnessNet get net => widget.net;

  /// The round I already scored in (don't relaunch on late score echoes).
  int _playedRound = 0;

  /// Inside the mini-game itself (playGo launches; onExit steps out).
  bool _inGame = false;

  /// The round whose GO already launched me (an exit doesn't relaunch).
  int _launchedRound = 0;

  /// The round whose intro countdown finished (locally).
  int _introDoneRound = 0;

  /// The round I answered (or skipped) the thumbs prompt for.
  int _feedbackRound = 0;

  Timer? _introTimer;
  int _introLeft = _kIntroSeconds;
  int _introTimerRound = 0;

  @override
  void initState() {
    super.initState();
    net.addListener(_onNet);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onNet());
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    net.removeListener(_onNet);
    net.dispose();
    super.dispose();
  }

  void _onNet() {
    if (!mounted) return;
    final playing = net.status == 'playing';
    // The spinner pulled GO → EVERY client launches together, once.
    if (playing &&
        net.playGo &&
        _playedRound < net.round &&
        _launchedRound < net.round) {
      _launchedRound = net.round;
      _inGame = true;
    }
    // A fresh game intro → run the 15s controls countdown.
    if (playing &&
        _playedRound < net.round &&
        _introDoneRound < net.round &&
        _introTimerRound < net.round) {
      _introTimerRound = net.round;
      _introLeft = _kIntroSeconds;
      _introTimer?.cancel();
      _introTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() {
          _introLeft--;
          if (_introLeft <= 0) {
            _introDoneRound = net.round;
            t.cancel();
          }
        });
      });
    }
    setState(() {});
  }

  /// Done reading — into the ready lobby (early tap or the timer's zero).
  void _finishIntro() {
    _introTimer?.cancel();
    setState(() => _introDoneRound = net.round);
  }

  void _onComplete(int score) {
    _playedRound = net.round;
    net.submitScore(score);
    setState(() => _inGame = false);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final spec = net.spec;
    // The game IS the screen while a round runs — the host owns clock,
    // results and exit; madness plumbing wraps it, never reaches inside.
    if (net.status == 'playing' && _inGame && spec != null) {
      return QuickRoomScope(
        code: net.code,
        myUid: net.myUid,
        isHost: net.isHost,
        seed: (net.meta?.seed ?? 0) + net.round,
        round: net.round,
        players: net.players,
        child: MiniGameHost(
          spec: spec,
          playerLabel: net.myPlayer?.name,
          onComplete: _onComplete,
          onExit: () => setState(() => _inGame = false),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Potatuhs.inkDeep,
      body: SafeArea(
        child: switch (net.status) {
          'lobby' => _lobbyView(),
          'spin' => MadnessSpinView(
              // Fresh wheel state every round.
              key: ValueKey('spin_${net.round}'),
              net: net,
            ),
          // playing: scored → waiting; intro (15s) → ready lobby → GO.
          'playing' => _playedRound >= net.round
              ? _waitingView()
              : _introDoneRound < net.round
                  ? _introView()
                  : _readyView(),
          'ceremony' => _ceremonyView(),
          'tiebreak' => MadnessTiebreakView(net: net),
          'done' => _finalView(),
          _ => _lobbyView(),
        },
      ),
    );
  }

  // ------------------------------------------------------------------ lobby

  Widget _lobbyView() {
    final players = net.players;
    final poolSize = net.availablePool.length;
    final spins = net.meta?.spinsPerPlayer ?? 1;
    final rounds = spins * players.length;
    final startable = net.canStart;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 8),
        Row(children: [
          _backButton(() => Navigator.of(context).maybePop()),
          const Spacer(),
        ]),
        const SizedBox(height: 10),
        Center(
          child: Text('MADNESS ROOM',
              style: Potatuhs.label(color: Potatuhs.textFaint)),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: net.code));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Potatuhs.inkPanel,
                duration: const Duration(seconds: 1),
                content: Text('Code copied',
                    style: Potatuhs.body(color: Potatuhs.gold)),
              ));
            },
            child: Text(
              net.code,
              style: Potatuhs.display(size: 54, color: Potatuhs.orange)
                  .copyWith(letterSpacing: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            '$poolSize games in the pool · $spins spin${spins == 1 ? '' : 's'} '
            'each · ${players.isEmpty ? '— rounds' : '$rounds round${rounds == 1 ? '' : 's'}'}',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary),
          ),
        ),
        const SizedBox(height: 18),
        Text('PLAYERS (${players.length}/${MadnessNet.kMaxPlayers})',
            style: Potatuhs.label(color: Potatuhs.textFaint)),
        const SizedBox(height: 8),
        ...players.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _avatar(p.character % kCharacters.length, size: 26),
                  const SizedBox(width: 10),
                  Text(p.name, style: Potatuhs.body(size: 18)),
                  const SizedBox(width: 6),
                  Text(kCharacters[p.character % kCharacters.length].name,
                      style:
                          Potatuhs.body(size: 12, color: Potatuhs.textFaint)),
                  if (p.uid == net.meta?.host) ...[
                    const SizedBox(width: 8),
                    Text('HOST', style: Potatuhs.label(color: Potatuhs.gold)),
                  ],
                ],
              ),
            )),
        const SizedBox(height: 18),
        _characterPicker(),
        const SizedBox(height: 24),
        if (net.isHost) ...[
          if (!startable && players.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Not enough games for $rounds rounds — enable more scales or '
                'lower the spins.',
                textAlign: TextAlign.center,
                style: Potatuhs.body(size: 13, color: Potatuhs.orange),
              ),
            ),
          PotatuhsButton(
            label: 'START THE MADNESS',
            display: true,
            icon: Icons.play_arrow,
            onTap: startable ? () => net.startGame() : () {},
            fill: startable ? Potatuhs.gold : Potatuhs.inkPanel,
            textColor: startable ? Potatuhs.ink : Potatuhs.textFaint,
          ),
        ] else
          Center(
            child: Text('Waiting for the host to start…',
                style: Potatuhs.body(size: 15, color: Potatuhs.textSecondary)),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _characterPicker() {
    final me = net.myPlayer;
    return CharacterPicker(
      selected: me?.character,
      taken: {
        for (final p in net.players)
          if (p.uid != me?.uid) p.character
      },
      onPick: (i) => net.chooseCharacter(i),
    );
  }

  Widget _avatar(int i, {double size = 28}) {
    final c = kCharacters[i % kCharacters.length];
    if (c.asset != null) {
      return ClipOval(
        child: Image.asset(
          c.asset!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _colorDot(c.color, size),
        ),
      );
    }
    return _colorDot(c.color, size);
  }

  Widget _colorDot(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _backButton(VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: Potatuhs.surface(
            fill: Potatuhs.inkPanel,
            radius: 12,
            borderColor: Colors.white12,
          ),
          child: const Icon(Icons.arrow_back,
              color: Potatuhs.textSecondary, size: 20),
        ),
      );

  // ------------------------------------------------------------- game intro

  /// The wheels landed: the host explains the game; the PLAYER launches it.
  Widget _introView() {
    final spec = net.spec;
    if (spec == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ROUND ${net.round} / ${net.totalRounds}',
                  textAlign: TextAlign.center,
                  style: Potatuhs.body(size: 12, color: Potatuhs.textSecondary)
                      .copyWith(letterSpacing: 3),
                ),
                const SizedBox(height: 8),
                Text(spec.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Potatuhs.display(size: 28, color: spec.accent)),
                const SizedBox(height: 4),
                Text(spec.tagline,
                    textAlign: TextAlign.center,
                    style: Potatuhs.body(
                        size: 14, color: Potatuhs.textSecondary)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: BoxDecoration(
                    color: Potatuhs.inkPanel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: spec.accent.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final rule in spec.rules) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.circle, size: 7, color: spec.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(rule,
                                  style: Potatuhs.body(
                                      size: 14,
                                      color: Potatuhs.textPrimary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DialogueStrip(beat: madnessGameIntroBeat(spec)),
                const SizedBox(height: 20),
                // ~15 seconds to pick up the controls, then the ready lobby
                // (Brett 2026-07-17). GOT IT skips ahead.
                Center(
                  child: Text(
                    'READY LOBBY IN ${_introLeft}s',
                    style: Potatuhs.body(size: 12, color: Potatuhs.textFaint)
                        .copyWith(letterSpacing: 3),
                  ),
                ),
                const SizedBox(height: 10),
                PotatuhsButton(
                  label: 'GOT IT',
                  display: true,
                  icon: Icons.check,
                  onTap: _finishIntro,
                  fill: Potatuhs.gold,
                  textColor: Potatuhs.ink,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- ready-up

  /// The pre-game lobby: everyone who's readied, live; the round's spinner
  /// drives GO once all are in, and every client launches together.
  Widget _readyView() {
    final spec = net.spec;
    final spinner = net.currentSpinner;
    final ready = net.readyUids.toSet();
    final allIn = net.allReady;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 8),
        Row(children: [
          _backButton(() => Navigator.of(context).maybePop()),
          const Spacer(),
        ]),
        const SizedBox(height: 8),
        Text('ROUND ${net.round} / ${net.totalRounds} · '
            '${spec?.name.toUpperCase() ?? ''}',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 12, color: Potatuhs.textSecondary)
                .copyWith(letterSpacing: 3)),
        const SizedBox(height: 6),
        Text('READY UP',
            textAlign: TextAlign.center,
            style: Potatuhs.display(size: 26, color: Potatuhs.gold)),
        const SizedBox(height: 4),
        Text('The game starts for everyone at once.',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary)),
        const SizedBox(height: 16),
        for (final p in net.players)
          _row(
            p,
            trailing: ready.contains(p.uid)
                ? const Icon(Icons.check_circle,
                    color: Potatuhs.gold, size: 22)
                : Text('…',
                    style: Potatuhs.display(
                        size: 18, color: Potatuhs.textFaint)),
          ),
        const SizedBox(height: 20),
        if (net.playGo)
          // Stepped out of a running game — the room is already playing.
          PotatuhsButton(
            label: 'REJOIN THE GAME',
            display: true,
            icon: Icons.play_arrow,
            onTap: () => setState(() => _inGame = true),
            fill: Potatuhs.gold,
            textColor: Potatuhs.ink,
          )
        else if (!net.amReady)
          PotatuhsButton(
            label: "I'M READY",
            display: true,
            icon: Icons.check,
            onTap: () => net.sendReady(),
            fill: Potatuhs.gold,
            textColor: Potatuhs.ink,
          )
        else if (allIn && net.isMyTurn)
          // Everyone's in — the spinner's seat drives the start.
          PotatuhsButton(
            label: 'START — EVERYONE PLAYS',
            display: true,
            icon: Icons.play_arrow,
            onTap: () => net.sendGo(),
            fill: Potatuhs.gold,
            textColor: Potatuhs.ink,
          )
        else
          Center(
            child: Text(
              allIn
                  ? 'Waiting for ${spinner?.name ?? 'the spinner'} to '
                      'start…'
                  : 'Waiting for everyone to ready up…',
              textAlign: TextAlign.center,
              style: Potatuhs.body(size: 14, color: Potatuhs.textSecondary),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --------------------------------------------------------------- waiting

  /// I scored; scores fill in live until the host device calls the round.
  Widget _waitingView() {
    final spec = net.spec;
    final rows = [...net.players]..sort((a, b) =>
        (net.scores[b.uid] ?? -1).compareTo(net.scores[a.uid] ?? -1));
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 8),
        Row(children: [
          _backButton(() => Navigator.of(context).maybePop()),
          const Spacer(),
        ]),
        const SizedBox(height: 8),
        Text('SCORES LANDING…',
            textAlign: TextAlign.center,
            style: Potatuhs.display(size: 22, color: Potatuhs.gold)),
        const SizedBox(height: 4),
        Text(
          '${spec?.name ?? ''} · round ${net.round} / ${net.totalRounds}',
          textAlign: TextAlign.center,
          style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary),
        ),
        const SizedBox(height: 18),
        for (final p in rows)
          _row(
            p,
            trailing: net.scores.containsKey(p.uid)
                ? Text('${net.scores[p.uid]}',
                    style: Potatuhs.display(size: 20, color: Potatuhs.gold))
                : Text('…',
                    style: Potatuhs.display(
                        size: 20, color: Potatuhs.textFaint)),
          ),
        const SizedBox(height: 18),
        Text('The ceremony starts once everyone lands.',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 13, color: Potatuhs.textFaint)),
        // Escape hatch: a dropped player can't strand the room — the host
        // may close the round with the scores that made it in.
        if (net.isHost && !net.allScored) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => net.callRound(),
              child: Text(
                'Someone stuck? Call the round with the scores in.',
                style: Potatuhs.body(size: 12, color: Potatuhs.textFaint)
                    .copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------- ceremony

  Widget _ceremonyView() {
    final m = net.meta;
    final leaderboard = net.leaderboard;
    final leader = leaderboard.isEmpty ? null : leaderboard.first;
    final roundsLeft = net.totalRounds - net.round;
    final last = roundsLeft <= 0;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 8),
        Row(children: [
          _backButton(() => Navigator.of(context).maybePop()),
          const Spacer(),
        ]),
        const SizedBox(height: 8),
        Text('ROUND ${net.round} / ${net.totalRounds}',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 12, color: Potatuhs.textSecondary)
                .copyWith(letterSpacing: 3)),
        const SizedBox(height: 6),
        Text('CEREMONY',
            textAlign: TextAlign.center,
            style: Potatuhs.display(size: 26, color: Potatuhs.gold)),
        const SizedBox(height: 18),
        // The podium: 1st on the left → last on the right, scrollable.
        MadnessBars(
          ordered: leaderboard,
          totals: m?.totals ?? const {},
          awards: m?.lastAward,
        ),
        const SizedBox(height: 16),
        DialogueStrip(
          beat: madnessCeremonyBeat(
              leaderName: leader?.name ?? '—', roundsLeft: roundsLeft),
        ),
        // One-tap thumbs on the game just played — optional, never blocks
        // (Brett 2026-07-17): skipping just moves on.
        if (net.spec != null && _feedbackRound < net.round) ...[
          const SizedBox(height: 14),
          FeedbackPrompt(
            gameId: net.spec!.id,
            gameName: net.spec!.name,
            source: 'madness',
            onDone: () => setState(() => _feedbackRound = net.round),
          ),
        ],
        const SizedBox(height: 20),
        if (net.isHost)
          PotatuhsButton(
            label: last ? 'CROWN THE CHAMPION' : 'NEXT SPIN',
            display: true,
            icon: last ? Icons.emoji_events : Icons.track_changes,
            onTap: () => net.advance(),
            fill: Potatuhs.gold,
            textColor: Potatuhs.ink,
          )
        else
          Center(
            child: Text('Waiting for the host…',
                style:
                    Potatuhs.body(size: 14, color: Potatuhs.textSecondary)),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ------------------------------------------------------------------ final

  Widget _finalView() {
    final leaderboard = net.leaderboard;
    final totals = net.meta?.totals ?? const {};
    final top = leaderboard.isEmpty ? 0 : (totals[leaderboard.first.uid] ?? 0);
    var champs = [
      for (final p in leaderboard)
        if ((totals[p.uid] ?? 0) == top) p
    ];
    // A settled tiebreak crowns exactly one — the hot potato has spoken.
    final tbWinner = net.tbWinner.isEmpty ? null : net.playerByUid(net.tbWinner);
    if (tbWinner != null) champs = [tbWinner];
    final tied = champs.length > 1;
    final title = tied
        ? champs.map((p) => p.name.toUpperCase()).join(' & ')
        : (champs.isEmpty ? '—' : champs.first.name.toUpperCase());
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 32),
        const Center(
          child:
              Icon(Icons.emoji_events, color: Potatuhs.gold, size: 56),
        ),
        const SizedBox(height: 8),
        Text(tied ? 'DEAD HEAT' : 'CHAMPION',
            textAlign: TextAlign.center,
            style: Potatuhs.label(color: Potatuhs.textFaint)),
        const SizedBox(height: 6),
        Text(title,
            textAlign: TextAlign.center,
            style: Potatuhs.display(size: 32, color: Potatuhs.gold)),
        if (tbWinner != null) ...[
          const SizedBox(height: 4),
          Text('won the hot potato tiebreaker',
              textAlign: TextAlign.center,
              style: Potatuhs.body(size: 12, color: Potatuhs.orange)),
        ],
        const SizedBox(height: 20),
        MadnessBars(
          ordered: leaderboard,
          totals: totals,
          highlightUids: {for (final p in champs) p.uid},
        ),
        const SizedBox(height: 16),
        if (champs.isNotEmpty)
          DialogueStrip(beat: madnessFinalBeat(champs.first.name)),
        const SizedBox(height: 20),
        // A dead heat doesn't end in a handshake — the hot potato settles it.
        if (tied) ...[
          if (net.isHost)
            PotatuhsButton(
              label: 'SETTLE IT — HOT POTATO',
              display: true,
              icon: Icons.local_fire_department,
              onTap: () => net.startTiebreak(),
              fill: Potatuhs.orange,
              textColor: Potatuhs.ink,
            )
          else
            Center(
              child: Text(
                'Dead heat! Waiting for the host to start the tiebreaker…',
                textAlign: TextAlign.center,
                style: Potatuhs.body(size: 14, color: Potatuhs.textSecondary),
              ),
            ),
          const SizedBox(height: 12),
        ],
        PotatuhsButton(
          label: 'EXIT',
          display: true,
          icon: Icons.logout,
          onTap: () => Navigator.of(context).maybePop(),
          fill: Potatuhs.inkPanel,
          textColor: Potatuhs.textPrimary,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ----------------------------------------------------------------- pieces

  Widget _row(NetPlayer p, {int? place, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Potatuhs.inkPanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (place != null)
            SizedBox(
              width: 26,
              child: Text('$place',
                  style: Potatuhs.display(
                      size: 16, color: Potatuhs.textSecondary)),
            ),
          _avatar(p.character % kCharacters.length, size: 26),
          const SizedBox(width: 10),
          Expanded(child: Text(p.name, style: Potatuhs.body(size: 15))),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
