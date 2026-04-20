import 'game_state.dart';

abstract class GameAction {
  const GameAction();
}

class MovePlayer extends GameAction {
  final Vec2 direction;
  const MovePlayer(this.direction);
}

class Tick extends GameAction {
  final double dt;
  const Tick(this.dt);
}

class DashAction extends GameAction {
  const DashAction();
}

class EjectMassAction extends GameAction {
  const EjectMassAction();
}

class RestartGame extends GameAction {
  const RestartGame();
}
