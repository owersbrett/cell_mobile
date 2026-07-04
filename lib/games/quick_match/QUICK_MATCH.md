# QUICK MATCH — single-game rooms

Play ONE catalog game with friends via a 4-letter room code. This is the
"every game is testable with friends" layer — the gate before party-mode
investment (roadmap locked 2026-07-03).

## What it is / isn't

- **Is:** a thin score-broadcast room around the untouched `MiniGameHost`.
  Host picks a game → room code → friends join → everyone plays the same
  `MiniGameSpec` simultaneously on their own device → scores land on a live
  standings board → host rematches without re-entering codes.
- **Isn't:** the party board's lockstep replay. There is no request queue, no
  canonical input log, no random tape — real-time mini-games run locally;
  only roster/start/scores synchronise. Do not graft `PartyNet` onto this.

## Files

| File | Role |
|---|---|
| `quick_match_transport.dart` | The pipe: `QuickMatchTransport` (abstract) + `FirebaseQuickMatchTransport` (RTDB) + `InMemoryQuickMatchTransport` (tests). |
| `quick_match_net.dart` | The coordinator: `QuickMatchNet` — host/join, startRound, submitScore, live standings. |
| `quick_match_page.dart` | The UI: setup → lobby → playing (`MiniGameHost`) → standings, one page. |

## Data model (RTDB)

Rooms share the party namespace `cell_games/$id` (same security rules; the
code IS the node id). A quick room is distinguished by meta shape — `specId`
present ⇒ quick match; `mode`/`rounds` ⇒ party board. `QuickMeta.tryParse`
returns null for non-quick metas, so a party code typed here fails politely.

```
cell_games/$id/
  meta:         { kind:'quick', host, specId, seed, status, round }
  players/$uid: { uid, name, slot, color, character }   (NetPlayer, reused)
  scores/$uid:  int
```

- `round` increments on every start. Clients relaunch when they see
  `status == 'playing'` with a round they haven't played — this is also the
  rematch mechanism. `startRound` bumps round + wipes scores in ONE multi-path
  update so a rematch can never show stale scores.
- A player joining mid-round is parked on the live standings and rides along
  from the next round.

## The bridge (zero per-game changes)

`MiniGameHost(spec, onComplete: net.submitScore, ...)` — non-null
`onComplete` puts the host in party mode (no AI opponents), exactly like the
board does at `party_page.dart`. Games never know they're networked.

## Entry points

- Per-scale game picker (`mini_game_page.dart` `_GameCard`): the group icon
  on any registry game → host a room for it.
- Games console (`games_debug_page.dart`): per-row group icon → host; app-bar
  group-add icon → join by code.

## Known limits (v1, accepted)

- Start sync is "status flip" — clients begin within RTDB latency of each
  other (fine for testing with friends; not esports).
- No character picker in the lobby (auto-assigned by seat).
- Host leaving orphans the room (party rooms share this; codes are cheap).
- Room nodes are never deleted (same as party rooms).
