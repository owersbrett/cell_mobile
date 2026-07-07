import 'package:cell_mobile/games/mini_game.dart';

import 'net/party_net.dart';
import 'party_controller.dart';
import 'party_models.dart';

/// The set of player-driven actions the party board UI can take. Abstracting
/// them lets the same screens drive either a LOCAL pass-and-play controller or
/// an ONLINE match (where genuine decisions are sent as intents to the host and
/// deterministic transitions are driven by the network instead of local taps).
abstract class PartyActions {
  void roll();
  void beginWalk();
  void advanceStep();
  void choosePath(int next);
  void buyPotato();
  void buyItem(PowerUp item);
  void skipPotato();
  void chooseCardOption(int option);
  void useItem(PowerUp item);
  void useItemOn(PowerUp item, int target);
  void useAtp(int plus);
  void wheelStop();
  void recordMiniScore(int score);
  void confirmSpace();
  void beginMiniGameRound();
  void startMiniGameAttempt();
  void confirmMiniGameResults();
  void debugSetSpec(MiniGameSpec spec);
}

/// Local pass-and-play: every action mutates the controller directly, exactly
/// as the board UI always has.
class LocalActions implements PartyActions {
  final PartyController c;
  const LocalActions(this.c);

  @override
  void roll() => c.roll();
  @override
  void beginWalk() => c.beginWalk();
  @override
  void advanceStep() => c.advanceStep();
  @override
  void choosePath(int next) => c.choosePath(next);
  @override
  void buyPotato() => c.buyPotato();
  @override
  void buyItem(PowerUp item) => c.buyItem(item);
  @override
  void skipPotato() => c.skipPotato();
  @override
  void chooseCardOption(int option) => c.chooseCardOption(option);
  @override
  void useItem(PowerUp item) => c.useItem(item);
  @override
  void useItemOn(PowerUp item, int target) => c.useItemOn(item, target);
  @override
  void useAtp(int plus) => c.useAtp(plus);
  @override
  void wheelStop() => c.wheelStop();
  @override
  void recordMiniScore(int score) => c.recordMiniScore(score);
  @override
  void confirmSpace() => c.confirmSpace();
  @override
  void beginMiniGameRound() => c.beginMiniGameRound();
  @override
  void startMiniGameAttempt() => c.startMiniGameAttempt();
  @override
  void confirmMiniGameResults() => c.confirmMiniGameResults();
  @override
  void debugSetSpec(MiniGameSpec spec) => c.debugSetSpec(spec);
}

/// Online: genuine decisions become intents sent to the host (which validates
/// and folds them into the canonical log). The deterministic transitions
/// (walking a step, confirming panels, starting/advancing mini-game rounds) are
/// driven by the host's published stream and replayed locally, so here they are
/// no-ops. Debug spec override is host-only and ignored on clients.
class OnlineActions implements PartyActions {
  final PartyNet net;
  const OnlineActions(this.net);

  @override
  void roll() => net.act(PartyInputKind.roll);
  @override
  void beginWalk() => net.act(PartyInputKind.beginWalk);
  @override
  void choosePath(int next) => net.act(PartyInputKind.choosePath, value: next);
  @override
  void buyPotato() => net.act(PartyInputKind.buyPotato);
  @override
  void buyItem(PowerUp item) =>
      net.act(PartyInputKind.buyItem, value: item.index);
  @override
  void skipPotato() => net.act(PartyInputKind.skipPotato);
  @override
  void chooseCardOption(int option) =>
      net.act(PartyInputKind.chooseCardOption, value: option);
  @override
  void useItem(PowerUp item) =>
      net.act(PartyInputKind.useItem, value: item.index);
  @override
  void useItemOn(PowerUp item, int target) =>
      net.act(PartyInputKind.useItemOn, value: item.index * 16 + target);
  @override
  void useAtp(int plus) => net.act(PartyInputKind.useAtp, value: plus);
  @override
  void wheelStop() => net.act(PartyInputKind.wheelStop);
  @override
  void recordMiniScore(int score) =>
      net.act(PartyInputKind.miniScore, value: score);
  @override
  void confirmMiniGameResults() => net.act(PartyInputKind.confirmResults);

  // Driven by the host's canonical stream, not by local taps.
  @override
  void advanceStep() {}
  @override
  void confirmSpace() {}
  @override
  void beginMiniGameRound() {}
  @override
  void startMiniGameAttempt() {}
  @override
  void debugSetSpec(MiniGameSpec spec) {}
}
