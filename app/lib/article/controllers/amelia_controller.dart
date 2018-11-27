import 'package:flare/flare.dart';
import 'package:flare/flare/math/mat2d.dart';
import 'package:flare/flare/math/vec2d.dart';
import 'flare_interaction_controller.dart';

class AmeliaController extends FlareInteractionController {
  ActorNode _ctrlFace;
  Vec2D _lastTouchPosition;
  Vec2D _originalTranslation;
  @override
  bool advance(
      FlutterActorArtboard artboard, Vec2D touchPosition, double elapsed) {
    if (touchPosition != null && _lastTouchPosition != null) {
      Vec2D move = Vec2D.subtract(Vec2D(), touchPosition, _lastTouchPosition);
      Mat2D toParentSpace = Mat2D();
      if (Mat2D.invert(toParentSpace, _ctrlFace.parent.worldTransform)) {
        Vec2D localMove = Vec2D.transformMat2(Vec2D(), move, toParentSpace);
        _ctrlFace.translation =
            Vec2D.add(Vec2D(), _ctrlFace.translation, localMove);
      }
    } else {
      _ctrlFace.translation = Vec2D.add(
          Vec2D(),
          _ctrlFace.translation,
          Vec2D.scale(
              Vec2D(),
              Vec2D.subtract(
                  Vec2D(), _originalTranslation, _ctrlFace.translation),
              (elapsed * 3.0).clamp(0.0, 1.0)));
    }
    _lastTouchPosition = touchPosition;
    return true;
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    _ctrlFace = artboard.getNode("ctrl_face");
    if (_ctrlFace != null) {
      _originalTranslation = Vec2D.clone(_ctrlFace.translation);
    }
  }
}
