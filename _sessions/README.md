# _sessions — concurrent-session ledger

Coordination state for multiple Claude sessions working this repo at once. See
"Multi-session protocol" in `CLAUDE.md` for the rules. This is a lock file plus a QA
checklist feeder — NOT a devlog (transcripts are the backstop for narrative).

One file per day: `YYYY-MM-DD.md`. Append-only; never rewrite another session's lines.

## Entry format

```
## <territory>            e.g. lib/games/financial/market_trader/  or  party/net
- CLAIM <HH:MM> — <goal in one line>
- REQUEST — <exact registry/catalog/shared-file edit needed, for the orchestrator>
- DONE <HH:MM> — files: <list> · verified: <analyze scope, played y/n> · dirty: <anything left>
```

- `CLAIM` before the first edit. A territory with a `CLAIM` and no `DONE` is locked.
- `REQUEST` lines are how per-game sessions get changes into orchestrator-only files
  (`mini_game_registry.dart`, `game_catalog.dart`, `party_page.dart`, `CLAUDE.md`, `docs/`).
- `DONE` closes the claim and feeds the integration QA pass (claims vs. git diff,
  one authoritative analyze, spot-play).

Orchestrator claims use the territory `ORCHESTRATOR` and note which REQUEST lines were
applied.
