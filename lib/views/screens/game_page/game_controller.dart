import 'package:cell_mobile/game/game_action.dart';
import 'package:cell_mobile/game/game_engine.dart';
import 'package:cell_mobile/game/game_state.dart';
import 'package:flutter/foundation.dart';

class GameController extends ChangeNotifier {
  final GameEngine _engine = GameEngine();
  late GameState _state;
  Vec2 _joystickDirection = Vec2.zero;

  GameController() {
    _state = _engine.createInitialState();
  }

  GameState get state => _state;

  void setJoystickDirection(Vec2 direction) {
    _joystickDirection = direction;
  }

  void tick(double dt) {
    if (_joystickDirection.lengthSquared > 0.01) {
      _state = _engine.processAction(_state, MovePlayer(_joystickDirection));
    } else {
      _state = _engine.processAction(_state, const MovePlayer(Vec2.zero));
    }
    _state = _engine.processAction(_state, Tick(dt));
    notifyListeners();
  }

  void dash() {
    _state = _engine.processAction(_state, const DashAction());
    notifyListeners();
  }

  void ejectMass() {
    _state = _engine.processAction(_state, const EjectMassAction());
    notifyListeners();
  }

  void restart() {
    _state = _engine.processAction(_state, const RestartGame());
    _joystickDirection = Vec2.zero;
    notifyListeners();
  }
}
