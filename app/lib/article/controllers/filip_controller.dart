import 'package:flare/flare.dart';
import 'package:flare/flare/math/mat2d.dart';
import 'package:flare/flare/math/vec2d.dart';
import 'flare_interaction_controller.dart';

class FilipController extends FlareInteractionController {
  ActorAnimation _movePhone;
  ActorAnimation _swayPhone;
  double _movePhoneTime = 0.0;
  double _swayPhoneTime = 0.0;
  bool _tapped = false;

  @override
  bool advance(
      FlutterActorArtboard artboard, Vec2D touchPosition, double elapsed) {
    if (touchPosition != null) {
      _tapped = true;
    }
    if (_tapped) {
      _movePhoneTime += elapsed;
      if (_movePhoneTime >= _movePhone.duration) {
        _swayPhoneTime += elapsed;
      }
      _movePhone.apply(
          _movePhoneTime, artboard, (_movePhoneTime / 0.2).clamp(0.0, 1.0));
      if (_swayPhoneTime > 0.0) {
        _swayPhone.apply(_swayPhoneTime % 2.0, artboard, 1.0);
      }
    }
    return true;
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    _movePhone = artboard.getAnimation("move_phone");
    _swayPhone = artboard.getAnimation("phone_sway");
  }
}
