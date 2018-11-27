import 'package:flare/flare.dart' as flare;
import 'package:flare/flare/math/mat2d.dart' as flare;
import 'package:flare/flare/math/vec2d.dart' as flare;

abstract class FlareInteractionController {
  void initialize(flare.FlutterActorArtboard artboard);
  bool advance(flare.FlutterActorArtboard artboard, flare.Vec2D touchPosition,
      double elapsed);
}
