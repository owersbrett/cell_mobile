# THE OPENING ORDER + SOLO CPUs (+ tap-to-drive law enforcement)

**Status: LOCKED (Brett, yumutsu, 2026-07-12).** Rules revision **6**.
Companions: `READY_UP_SPEC.md` (rev 5), `ITEMS_SPEC.md` (the market), `MAPS_SPEC.md`.

## 0. What Brett saw (the driving observations)

1. The minimap appears behind the round ceremony podium. It belongs ONLY to dialog
   beats (round flair), where it anchors the narration.
2. Cutscenes drive themselves — flair beats auto-advance after their animation, and
   the reveal/ceremony auto-advance for the online host. He looked away and missed a
   beat. PARTY UX LAW: **every dialog/cutscene is tap-to-drive. No timer advances a
   held beat**, local or online. (ATTRACT mode is the one exception — it is a bot
   audience by definition.)
3. Solo party is playing alone. It should be the player vs **3 CPU characters**.
4. Turn order is silently seat order. It should be earned: an **opening double-dice
   roll-off ceremony** assigns the ordinals (1st…4th) — an important ritual moment.
   Two market items ride on it: a dice REROLL and an ORDER SWAP.

## 1. Tap-to-drive sweep (bug fix, no rules gate — presentation only)

| Auto-pacer | Today | Becomes |
|---|---|---|
| Round flair beats | auto-advance on 4.6s animation end (`round_flair.dart`) | animation plays, then HOLDS; tap advances. `auto: true` only under ATTRACT. |
| Round ceremony | online host auto-confirms after 6s | tap only (host taps online; ATTRACT confirms via its own autopilot). Dead `autoAdvance` plumbing removed. |
| Game reveal | online host `_AutoAdvanceAfter` 6s | tap only. Safe now: the reveal leads to the READY CHECK, which already holds for everyone. |

Known consequence, accepted: online, a distracted host stalls the reveal/ceremony —
their room, their tap. The players' escape hatches (vote-skip, ready check) all remain.

**Minimap:** `MiniMapBackdrop` is removed from `RoundCeremonyScreen`. The minimap
renders ONLY inside dialog beats (round flair).

## 2. Solo = 1 human + 3 CPUs

- `PartyMode.solo.playerCount` 1 → **4**. Seats 1–3 are CPU:
  `PartyController.isCpuSeat(i) => mode == solo && i > 0` — derived from the mode, so
  saves need no new field.
- Setup: the human picks their character; the 3 CPUs are drawn from the canonical cast
  (distinct, excluding the human's pick).
- **Board turns:** in local mode the party page auto-drives any CPU-owned decision
  after a short watchable beat (reusing the ATTRACT pacing table): roll, walk,
  branch pick, shop policy (buy potato when affordable), card option, COMPLETE TURN,
  their own wheel stops, their opening order rolls. The human watches; nothing CPU
  waits on a tap. All CPU decisions are ordinary logged inputs — replay-safe.
- **Mini-games:** the human plays their attempt normally. A CPU's attempt is not
  played out: when the pending mini-player is a CPU, the page banks a fabricated
  score after a beat — `OpponentRoster` difficulty band × `spec.humanMax` (the same
  calibration `MiniGameHost` uses for solo LEARN opponents). Logged via
  `recordMiniScore(player: seat)`.
- Cutscenes (reveal, flair, ceremony) stay tap-driven — the human is present.

## 3. The opening order ceremony (rules ≥ 6)

- New phase `orderRoll` + new input `orderRoll` (both APPENDED — index-stable).
- Match start (rules ≥ 6): instead of dropping into seat 0's turn, the match opens in
  `orderRoll`. Every seat rolls **two dice** (tape draws — lockstep/replay safe), one
  seat at a time, each roll its own logged input (player = seat).
- **Resolution — tie groups:** maintain ordered groups, initially `[[all seats]]`.
  When every seat of the first non-singleton group has rolled, split it by total
  (descending). Any subgroup with >1 seat re-rolls (only those seats; fresh dice).
  Repeat until all groups are singletons → `turnOrder` = the flattened list:
  ordinal 1 rolls first each round, then 2, 3, 4.
- **Turn cycling** follows `turnOrder` everywhere: `_endTurn` advances a cursor
  through it; round boundaries reset the cursor to ordinal 1. `currentPlayerIndex`
  stays the seat index (nothing else changes meaning). Rules ≤ 5: `turnOrder` is the
  identity and the phase never fires — old logs replay byte-identical.
- **UI:** `_OrderRollScreen` — the cast lined up, the pending seat's ROLL button
  (online: only that seat's device is interactive; solo: CPUs roll on a beat), dice
  results shown per character, TIE beats announced, final ordinal reveal
  ("X GOES FIRST…"), tap to continue into round 1. Tap-driven per the law.
- Online: `orderRoll` validated host-side (pending seat only). The pump treats
  `orderRoll` as a genuine decision phase (holds).

## 4. The two order items (market catalog additions, rules ≥ 6)

| Item | Rarity / price | Play window | Effect |
|---|---|---|---|
| `reroll` — MULLIGAN | rare, 13💎 | `rollResult` (your own dice, incl. boosted/multi-dice rolls) | throw the same dice again (fresh tape draws); the new result stands — no take-backs on the reroll. |
| `orderSwap` — QUEUE JUMPER | exotic, 28💎 | your `turnStart`, targeted (Strong Bond blocks) | exchange YOUR ordinal with the target's **from the next round** (queued at the round boundary, so nobody gains or loses a turn mid-round). |

*(Prices amended during implementation, 2026-07-12: the draft's 7/14 violated the
locked ITEMS_SPEC bands — rare 12–18, exotic 25+ i.e. above a potato. Now 13/28.
Shelf draws use rules-gated V6 pools so pre-6 seeded replays keep their shelves.)*

Both appended to `PowerUp` (index-stable), added to the catalog shelf + prices.
The market shelf is tape-drawn, so replays are unaffected; both items are only
purchasable in rules ≥ 6 matches (the shelf draw filters them out below 6).
Noted limitation (Brett, cyummu'd): items don't exist at match start, so MULLIGAN
cannot reroll the opening ceremony — it serves movement rolls.

## 5. Tests (`test/party/order_and_solo_test.dart` + flair/ceremony widget checks)

1. Rules ≥ 6 match opens in `orderRoll`; rules ≤ 5 opens in `turnStart` (pin).
2. Order resolution: distinct totals → ordinals by total desc; forced tie → only the
   tied seats re-roll; multi-level ties converge; `turnOrder` is a permutation.
3. Turn cycling follows `turnOrder` across a full round and resets each round.
4. Full-log replay (`PartyController.replay`) with orderRoll inputs → identical
   `turnOrder`, phase, state. Lockstep client replay (`replayWithRandoms`) converges.
5. MULLIGAN: rerolls dice at rollResult, consumed, new steps walked; illegal outside
   rollResult.
6. QUEUE JUMPER: swap queued mid-round, applied at the boundary; both seats keep
   exactly one turn per round across the swap.
7. Solo: a full solo match (1 human driving, CPU inputs simulated as the page would)
   reaches gameOver; CPU seats never block; every round has 4 mini-scores.
8. Widget: flair beat does NOT advance after its animation without a tap; advances on
   tap; ceremony renders no minimap.

## 6. Files

| File | Change |
|---|---|
| `party_controller.dart` | `orderRoll` phase+input, tie-group state + `turnOrder`, cursor-based `_endTurn`/round reset, `readyUp`-style `orderRollFor(seat)`, `reroll`/`orderSwap` effects, `kPartyRules = 6` + rev doc, pump hold |
| `party_models.dart` | `PowerUp.reroll`/`orderSwap` (appended) + catalog/prices/rarity, solo `playerCount` 4 |
| `party_actions.dart` / `party_net.dart` | `orderRoll` action + host validation |
| `party_page.dart` | surgical: `_OrderRollScreen` (appended), orderRoll case, CPU auto-driver (solo), CPU mini-score banking, reveal auto-advance removed |
| `round_ceremony.dart` | minimap backdrop removed, auto-advance plumbing removed |
| `round_flair.dart` | tap-to-advance (auto only under ATTRACT) |
| `party_setup_page.dart` | solo roster (human + 3 distinct CPUs) |
| tests | `test/party/order_and_solo_test.dart` (new), flair/ceremony widget checks |
