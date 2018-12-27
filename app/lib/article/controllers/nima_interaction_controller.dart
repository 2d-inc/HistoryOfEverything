import 'package:nima/nima.dart' as nima;
import 'package:nima/nima/math/mat2d.dart' as nima;
import 'package:nima/nima/math/vec2d.dart' as nima;

/// Controllers are used in our Flare library to provide custom behaviors for animations.
abstract class NimaInteractionController {
  /// This'll be called upon initialization: use it to set up the controller.
  /// Generally that means grabbing the references to the Actor nodes that
  /// will be performing a custom action.
  void initialize(nima.FlutterActor actor);

  /// This callback is used to advance the controller when the animation itself is advancing.
  bool advance(
      nima.FlutterActor actor, nima.Vec2D touchPosition, double elapsed);
}
