# READY UP — the mini-game ready check (online party)

**Status: LOCKED (Brett, yumutsu, 2026-07-12).** The spec outranks the implementation
(CLAUDE.md rule 2).

## 0. The law

Online, **no mini-game round begins until every seat has readied up.** Today the online
flow plunges: the moment the game reveal is advanced (host tap or its 6-second auto-dwell),
`_pumpToDecision` fast-forwards `passPhone → minigamePlaying` on every replica
(`party_controller.dart:2301`) and each player is dropped into `MiniGameHost`'s local
intro on their own clock — player A can be 20 seconds into the game while player B is
still reading the rules. This spec makes the round start a **player decision**, extending
PARTY UX LAW ("the player drives; the machine never plunges") and the existing net-layer
philosophy ("the players decide, not a timer" — `party_net.dart:265`).

## 1. Player experience (online)

1. **Game reveal** (`minigameIntro`) — unchanged. Host taps or the 6s auto-dwell fires.
   The dwell is now harmless: it can only move the room into the ready check, never into
   gameplay.
2. **READY CHECK** (new screen, rendered for the `passPhone` phase online) — every player
   sees: the game's icon/name/how-to-win **and its rules text** (this replaces the
   per-player `MiniGameHost` intro as reading time), the armed Big Bad decree banner when
   present, the roster with per-seat ready pips (`READY 2/4`), a big **READY** button, and
   the **VOTE SKIP** button. Tapping READY flips the button to `WAITING FOR OTHERS…`;
   the pips fill in live as seats ready.
3. **Synchronized start** — the instant the last seat readies, every replica transitions
   to `minigamePlaying` on the same canonical input. `MiniGameHost` mounts with
   `autoStart: true`: a short settle beat, then straight into the shared 3-2-1 countdown.
   No second START tap; everyone's game begins together (modulo transit latency).
4. **After a player finishes** — unchanged: submitted players sit on the
   "Waiting for others…" overlay; the round resolves when every score is in.

**Offline pass-and-play is untouched**: the pass-phone screen keeps its direct
START-tap (`startMiniGameAttempt`), attempts stay sequential, and attract/autopilot keeps
auto-advancing. The ready check exists only where seats live on different devices.

## 2. Mechanics

### 2.1 New input: `PartyInputKind.readyUp`
- **Appended at the END of the enum** (wire format is `kind.index` — appending keeps every
  existing log/save byte-compatible).
- `player` = the readying seat (like `voteSkip`/`miniScore`); `value` unused.
- Logged, so every replica and late-joiner replay reconstructs the same set.

### 2.2 Controller state
- `final Set<int> readySeats = {}` — cleared in `_startMiniGameRound()` and in
  `_skipMiniGameRound()`.
- `bool get allSeatsReady => readySeats.length >= players.length`.
- `void readyUp({int? player})` — legal only in `passPhone`; idempotent per seat (a
  repeat is a no-op, not a re-log); logs the input, adds a turn-log line
  (`NAME is ready (2/4)`); when the set completes, calls `startMiniGameAttempt()`
  directly — the phase transition rides the last `readyUp` input, so lockstep replicas
  agree by construction.
- **A skip vote implies ready.** `voteSkip` during the ready check also marks the voter's
  seat ready (and logs only the `voteSkip` input — replay derives the ready mark the same
  way). Rationale: a failed skip protest must not deadlock the room; one interaction =
  that seat has responded.

### 2.3 The gate (rules revision 5)
- `kPartyRules: 4 → 5`. In `_pumpToDecision`, the `passPhone` case becomes:
  hold (return) when `rules >= 5 && !allSeatsReady`; otherwise fast-forward as today.
- `passPhone` is thereby a **genuine decision phase** for rules-5 matches, exactly like
  the ceremony.
- Re-entries after scores pump through untouched: `recordMiniScore` bounces the phase to
  `passPhone` between submissions, but `readySeats` is still full from the round start,
  so the gate is open until the next `_startMiniGameRound()` clears it.
- Old logs/saves (`rules <= 4`) replay byte-identically — the gate never engages. (Even
  if it did, `miniScore` is already legal in `passPhone`, so no old log can stall.)

### 2.4 Net layer (`party_net.dart`)
- `_applyRequest` gains a `readyUp` case: legal when
  `phase == passPhone && !readySeats.contains(slot)`; applies as
  `c.readyUp(player: slot)`.
- **Host-side enforcement** (sharpened during implementation, 2026-07-12):
  `miniScore` requests are REJECTED while the ready check holds — a score in
  `passPhone` is legal only once `allSeatsReady` (the between-submission
  re-entry). The lock is enforced by the host validator, not just the screens.
- `OnlineActions.readyUp()` → `net.act(PartyInputKind.readyUp)` (seat attribution follows
  the `miniScore` pattern). `LocalActions.readyUp()` → `c.readyUp()` (unused by offline
  UI, present for interface symmetry).
- **No timer, no watchdog.** A seat that never readies holds the room, by design; the
  escape hatch is the existing VOTE SKIP majority (castable from the ready screen).

### 2.5 `MiniGameHost` (shared host — surgical)
- New param `autoStart` (default `false`): on mount, skip the local intro and start the
  countdown after a ~400ms settle beat. Nothing inside any game changes; solo/LEARN,
  quick match, and offline party paths are untouched (they never pass it).
- Consequence: online, the vote-skip window is the intro + ready check (the `introAction`
  row no longer exists online since the local intro is skipped). Offline keeps the intro
  row exactly as today. The principle "skip never sits over live gameplay" is preserved.

## 3. Edge cases
- **Disconnect during ready check**: the room holds. Majority VOTE SKIP moves everyone
  past the round. Known limitation: a 2-player room whose partner vanishes cannot form a
  skip majority (1×2 ≯ 2) — that is a pre-existing roster-departure gap (see
  `MULTIPLAYER_HANDOFF.md`), not created here; fixing departures is separate work.
- **Late joiner / reconnect**: replays the canonical log; `readyUp` inputs rebuild
  `readySeats`, so a rejoin mid-ready-check lands on the ready screen with correct pips.
- **Big Bad decree rounds**: unchanged — decree arms before the reveal; the ready screen
  re-shows the banner; a majority skip still fizzles the decree.
- **Version skew online**: enum append keeps old-log indices stable; mixed-build rooms
  are a pre-existing hazard of the web deploy model (all clients load the same build).

## 4. Tests (`test/party/ready_up_test.dart` — the stability contract)
1. `readyUp` marks the seat; a repeat neither re-logs nor double-counts.
2. Phase holds at `passPhone` through `advanceToDecision()` until ALL seats ready
   (the lock the feature exists for).
3. The last `readyUp` transitions every replica to `minigamePlaying` — verified via
   `replayWithRandoms` lockstep (host log → client replay → identical phase + state).
4. `readySeats` clears at the next mini-game round: round 2 requires fresh readies.
5. A skip vote marks the voter ready; a majority skip from the ready check skips the
   round (no scores, no ceremony) and clears both sets.
6. Score→`passPhone` re-entries pump through while the set is full (mid-round submissions
   never re-gate).
7. Rules ≤ 4 replay: `passPhone` fast-forwards exactly as before the feature (old-save
   compatibility pin).
8. Full-round replay determinism: a complete log containing `readyUp` inputs rebuilds via
   `PartyController.replay` to the identical end state.
9. Widget: `MiniGameHost(autoStart: true)` reaches countdown without a START tap;
   `autoStart: false` still holds at the intro.

## 5. Files touched
| File | Change |
|---|---|
| `lib/party/party_controller.dart` | `readyUp` input kind (appended) + apply case, `readySeats`, `readyUp()`, pump gate, `kPartyRules = 5` + rev-doc entry, round-start/skip clears |
| `lib/party/party_actions.dart` | `readyUp()` on the interface + both impls |
| `lib/party/net/party_net.dart` | `_applyRequest` readyUp case |
| `lib/party/screens/party_page.dart` | surgical: online `passPhone` case → `_ReadyCheckScreen` (new widget, appended) |
| `lib/games/mini_game_host.dart` | `autoStart` param |
| `test/party/ready_up_test.dart` | new suite (§4) |
