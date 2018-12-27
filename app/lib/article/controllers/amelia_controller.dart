import 'package:flare/flare.dart';
import 'package:flare/flare/math/mat2d.dart';
import 'package:flare/flare/math/vec2d.dart';
import 'flare_interaction_controller.dart';

// "Amelia Earhart" Article Page contains a custom controller.
/// Since Amelias Earhart's animation was built in Flare, it'll interface with the Flare library (https://github.com/2d-inc/Flare-Flutter).
/// Take a look at the character at https://www.2dimensions.com/a/JuanCarlos/files/flare/amelia-earhart_v2/preview
class AmeliaController extends FlareInteractionController {
  /// The character has been set up so that the actor node with name "ctrl_face"
  /// is the target for the Translation Constraint set on the plane node and the face elements.
  /// That means that by grabbing a reference to that node, and tying its translation
  /// to the users' touch input on the screen, we can move the plane and that'll be followed along by
  /// Amelia's face elements.
  ActorNode _ctrlFace;
  /// Get a reference to the touch position and the original translation values.
  Vec2D _lastTouchPosition;
  Vec2D _originalTranslation;

  /// As seen in [FlareInteractionController], this method allows us to set up 
  /// local variables as needed. In this case we grab a reference to the controlling node
  /// and the original translation position for the face.
  @override
  void initialize(FlutterActorArtboard artboard) {
    _ctrlFace = artboard.getNode("ctrl_face");
    if (_ctrlFace != null) {
      _originalTranslation = Vec2D.clone(_ctrlFace.translation);
    }
  }

  /// This method must be called whenever the corresponding Flare [FlutterActor] is being advanced.
  /// By advancing the controller, we pass down the correct values at every frame and interpolate
  /// with the input touch values.
  @override
  bool advance(
      FlutterActorArtboard artboard, Vec2D touchPosition, double elapsed) {
    if (touchPosition != null && _lastTouchPosition != null) {
      Vec2D move = Vec2D.subtract(Vec2D(), touchPosition, _lastTouchPosition);
      Mat2D toParentSpace = Mat2D();
      /// Transform world coordinates into object space. Then evaluate the move delta
      /// and apply it to the control.
      if (Mat2D.invert(toParentSpace, _ctrlFace.parent.worldTransform)) {
        Vec2D localMove = Vec2D.transformMat2(Vec2D(), move, toParentSpace);
        _ctrlFace.translation =
            Vec2D.add(Vec2D(), _ctrlFace.translation, localMove);
      }
    } else {
      /// If the finger has been lifted - i.e. [_lastTouchPosition] is null
      /// set the face position back to its original value.
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
}
