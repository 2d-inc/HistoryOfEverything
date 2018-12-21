import 'package:nima/nima.dart';
import 'package:nima/nima/actor_node.dart';
import 'package:nima/nima/math/mat2d.dart';
import 'package:nima/nima/math/vec2d.dart';
import 'nima_interaction_controller.dart';

/// "Newton's Theory of Gravity" Article Page contains a custom controller.
/// Since Newton's animation was built in Nima, it'll interface with the Nima library (https://github.com/2d-inc/Nima-Flutter).
/// Take a look at the character at https://www.2dimensions.com/a/JuanCarlos/files/nima/newton_v2/preview
class NewtonController extends NimaInteractionController {
  /// The character has been set up so that the actor node with name "ctrl_move_tree"
  /// is the target for the Inverse Kinematic (IK) Constraint set on the tree trunk.
  /// That means that by grabbing a reference to that node, and tying its translation
  /// to the users' touch input on the screen, we can move the tree trunk.
  ActorNode _treeControl;
  /// Two vector variables are used to store the actual coordinates.
  Vec2D _lastTouchPosition;
  Vec2D _originalTranslation;

  /// As seen in [NimaInteractionController], this method allows us to set up 
  /// local variables as needed. In this case, we grab the reference to controlling node
  /// and the original translation position for the tree trunk.
  @override
  void initialize(FlutterActor artboard) {
    _treeControl = artboard.getNode("ctrl_move_tree");
    if (_treeControl != null) {
      _originalTranslation = Vec2D.clone(_treeControl.translation);
    }
  }

  /// This method must be called whenever the corresponding Nima [FlutterActor] is being advanced.
  /// By advancing the controller, we pass down the correct values at every frame and interpolate
  /// with the input touch values.
  @override
  bool advance(FlutterActor artboard, Vec2D touchPosition, double elapsed) {
    if (touchPosition != null && _lastTouchPosition != null) {
      Vec2D move = Vec2D.subtract(Vec2D(), touchPosition, _lastTouchPosition);
      Mat2D toParentSpace = Mat2D();
      /// Transform world coordinates into object space. Then evaluate the move delta
      /// and apply it to the control.
      if (Mat2D.invert(toParentSpace, _treeControl.parent.worldTransform)) {
        Vec2D localMove = Vec2D.transformMat2(Vec2D(), move, toParentSpace);
        _treeControl.translation =
            Vec2D.add(Vec2D(), _treeControl.translation, localMove);
      }
    } else {
      /// If the finger has been lifted - i.e. [_lastTouchPosition] is null
      /// set the tree's position back to its original value.
      _treeControl.translation = Vec2D.add(
          Vec2D(),
          _treeControl.translation,
          Vec2D.scale(
              Vec2D(),
              Vec2D.subtract(
                  Vec2D(), _originalTranslation, _treeControl.translation),
              (elapsed * 3.0).clamp(0.0, 1.0)));
    }
    _lastTouchPosition = touchPosition;
    return true;
  }
}
