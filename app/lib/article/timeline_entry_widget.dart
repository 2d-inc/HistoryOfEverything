import 'dart:math';
import 'dart:ui';
import "dart:ui" as ui;

import 'package:flare/flare.dart' as flare;
import 'package:flare/flare/actor_image.dart' as flare;
import 'package:flare/flare/math/aabb.dart' as flare;
import 'package:flare/flare/math/mat2d.dart' as flare;
import 'package:flare/flare/math/vec2d.dart' as flare;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:nima/nima.dart' as nima;
import 'package:nima/nima/actor_image.dart' as nima;
import 'package:nima/nima/math/aabb.dart' as nima;
import 'package:nima/nima/math/vec2d.dart' as nima;
import 'package:timeline/article/controllers/amelia_controller.dart';
import 'package:timeline/article/controllers/flare_interaction_controller.dart';
import 'package:timeline/article/controllers/newton_controller.dart';
import 'package:timeline/article/controllers/nima_interaction_controller.dart';
import 'package:timeline/timeline/timeline_entry.dart';

/// This widget renders a single [TimelineEntry]. It relies on a [LeafRenderObjectWidget] 
/// so it can implement a custom [RenderObject] and update it accordingly.
class TimelineEntryWidget extends LeafRenderObjectWidget {
  /// A flag is used to animate the widget only when needed.
  final bool isActive;
  final TimelineEntry timelineEntry;
  /// If this widget also has a custom controller, the [interactOffset]
  /// parameter can be used to detect motion effects and alter the [FlareActor] accordingly.
  final Offset interactOffset;

  TimelineEntryWidget(
      {Key key, this.isActive, this.timelineEntry, this.interactOffset})
      : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return VignetteRenderObject()
      ..timelineEntry = timelineEntry
      ..isActive = isActive
      ..interactOffset = interactOffset;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant VignetteRenderObject renderObject) {
    renderObject
      ..timelineEntry = timelineEntry
      ..isActive = isActive
      ..interactOffset = interactOffset;
  }

  @override
  didUnmountRenderObject(covariant VignetteRenderObject renderObject) {
    renderObject
      ..isActive = false
      ..timelineEntry = null;
  }
}


/// When extending a [RenderBox] we provide a custom set of instructions for the widget being rendered.
/// 
/// In particular this means overriding the [paint()] and [hitTestSelf()] methods to render the loaded
/// Flare/Nima [FlutterActor] where the widget is being placed.
class VignetteRenderObject extends RenderBox {
  static const Alignment alignment = Alignment.center;
  static const BoxFit fit = BoxFit.contain;
  
  bool _isActive = false;
  bool _firstUpdate = true;
  bool _isFrameScheduled = false;
  double _lastFrameTime = 0.0;
  Offset interactOffset;
  Offset _renderOffset;

  TimelineEntry _timelineEntry;
  nima.FlutterActor _nimaActor;
  flare.FlutterActorArtboard _flareActor;
  FlareInteractionController _flareController;
  NimaInteractionController _nimaController;

  /// Called whenever a new [TimelineEntry] is being set.
  updateActor() {
    if (_timelineEntry == null) {
      /// If [_timelineEntry] is removed, free its resources.
      _nimaActor?.dispose();
      _flareActor?.dispose();
      _nimaActor = null;
      _flareActor = null;
    } else {
      TimelineAsset asset = _timelineEntry.asset;
      if (asset is TimelineNima && asset.actor != null) {
        /// Instance [_nimaActor] through the actor reference in the asset
        /// and set the initial starting value for its animation.
        _nimaActor = asset.actor.makeInstance();
        asset.animation.apply(asset.animation.duration, _nimaActor, 1.0);
        _nimaActor.advance(0.0);
        if (asset.filename == "assets/Newton/Newton_v2.nma") {
          /// Newton uses a custom controller! =)
          _nimaController = NewtonController();
          _nimaController.initialize(_nimaActor);
        }
      } else if (asset is TimelineFlare && asset.actor != null) {
        /// Instance [_flareActor] through the actor reference in the asset
        /// and set the initial starting value for its animation.
        _flareActor = asset.actor.makeInstance();
        asset.animation.apply(asset.animation.duration, _flareActor, 1.0);
        _flareActor.advance(0.0);
        if (asset.filename == "assets/Amelia_Earhart/Amelia_Earhart.flr") {
          /// Amelia Earhart uses a custom controller too..!
          _flareController = AmeliaController();
          _flareController.initialize(_flareActor);
        }
      }
    }
  }

  /// Uses the [SchedulerBinding] to trigger a new paint for this widget.
  void updateRendering() {
    if (_isActive && _timelineEntry != null) {
      markNeedsPaint();
      if (!_isFrameScheduled) {
        _isFrameScheduled = true;
        SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
      }
    }
    markNeedsLayout();
  }

  TimelineEntry get timelineEntry => _timelineEntry;
  set timelineEntry(TimelineEntry value) {
    if (_timelineEntry == value) {
      return;
    }
    _timelineEntry = value;
    _firstUpdate = true;
    updateActor();
    updateRendering();
  }


  bool get isActive => _isActive;
  set isActive(bool value) {
    if (_isActive == value) {
      return;
    }
    _isActive = value;
    updateRendering();
  }

  /// The size of this widget is determined by its parent, for optimization purposes.
  @override
  bool get sizedByParent => true;

  /// Determine if this widget has been tapped. If that's the case, restart its animation.
  @override
  bool hitTestSelf(Offset screenOffset) {
    if (_timelineEntry != null) {
      TimelineAsset asset = _timelineEntry.asset;
      if (asset is TimelineNima && asset.actor != null) {
        asset.animationTime = 0.0;
      } else if (asset is TimelineFlare && asset.actor != null) {
        asset.animationTime = 0.0;
      }
    }
    return true;
  }

  @override
  void performResize() {
    size = constraints.biggest;
  }

  /// This overridden method is where we can implement our custom logic, for
  /// laying out the [FlutterActor], and drawing it to [canvas].
  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    TimelineAsset asset = _timelineEntry?.asset;
    _renderOffset = offset;

    /// Don't paint if not needed.
    if (_timelineEntry == null || asset == null) {
      return;
    }

    canvas.save();

    double w = asset.width;
    double h = asset.height;

    /// If the asset is just a static image, draw the image directly to [canvas].
    if (asset is TimelineImage) {
      canvas.drawImageRect(
          asset.image,
          Rect.fromLTWH(0.0, 0.0, asset.width, asset.height),
          Rect.fromLTWH(offset.dx + size.width - w, asset.y, w, h),
          Paint()
            ..isAntiAlias = true
            ..filterQuality = ui.FilterQuality.low
            ..color = Colors.white.withOpacity(asset.opacity));
    } else if (asset is TimelineNima && _nimaActor != null) {
      /// If we have a [TimelineNima] asset, set it up properly and paint it.
      /// 
      /// 1. Calculate the bounds for the current object.
      /// An Axis-Aligned Bounding Box (AABB) is already set up when the asset is first loaded.
      /// We rely on this AABB to perform screen-space calculations.
      nima.AABB bounds = asset.setupAABB;

      double contentHeight = bounds[3] - bounds[1];
      double contentWidth = bounds[2] - bounds[0];
      double x =
          -bounds[0] - contentWidth / 2.0 - (alignment.x * contentWidth / 2.0);
      double y = -bounds[1] -
          contentHeight / 2.0 +
          (alignment.y * contentHeight / 2.0);

      Offset renderOffset = offset;
      Size renderSize = size;

      double scaleX = 1.0, scaleY = 1.0;

      canvas.save();

      /// This widget is always set up to use [BoxFit.contain].
      /// But this behavior can be customized according to anyone's needs.
      /// The following switch/case contains all the various alternatives native to Flutter.
      switch (fit) {
        case BoxFit.fill:
          scaleX = renderSize.width / contentWidth;
          scaleY = renderSize.height / contentHeight;
          break;
        case BoxFit.contain:
          double minScale = min(renderSize.width / contentWidth,
              renderSize.height / contentHeight);
          scaleX = scaleY = minScale;
          break;
        case BoxFit.cover:
          double maxScale = max(renderSize.width / contentWidth,
              renderSize.height / contentHeight);
          scaleX = scaleY = maxScale;
          break;
        case BoxFit.fitHeight:
          double minScale = renderSize.height / contentHeight;
          scaleX = scaleY = minScale;
          break;
        case BoxFit.fitWidth:
          double minScale = renderSize.width / contentWidth;
          scaleX = scaleY = minScale;
          break;
        case BoxFit.none:
          scaleX = scaleY = 1.0;
          break;
        case BoxFit.scaleDown:
          double minScale = min(renderSize.width / contentWidth,
              renderSize.height / contentHeight);
          scaleX = scaleY = minScale < 1.0 ? minScale : 1.0;
          break;
      }

      /// 2. Move the [canvas] to the right position so that the widget's position
      /// is center-aligned based on its offset, size and alignment position.
      canvas.translate(
          renderOffset.dx +
              renderSize.width / 2.0 +
              (alignment.x * renderSize.width / 2.0),
          renderOffset.dy +
              renderSize.height / 2.0 +
              (alignment.y * renderSize.height / 2.0));
      /// 3. Scale depending on the [fit].
      canvas.scale(scaleX, -scaleY);
      /// 4. Move the canvas to the correct [_nimaActor] position calculated above.
      canvas.translate(x, y);
      /// 5. perform the drawing operations.
      _nimaActor.draw(canvas, 1.0);
      /// 6. Restore the canvas' original transform state.
      canvas.restore();
    } else if (asset is TimelineFlare && _flareActor != null) {
      /// If we have a [TimelineFlare] asset set it up properly and paint it.
      /// 
      /// 1. Calculate the bounds for the current object.
      /// An Axis-Aligned Bounding Box (AABB) is already set up when the asset is first loaded.
      /// We rely on this AABB to perform screen-space calculations.
      flare.AABB bounds = asset.setupAABB;
      double contentWidth = bounds[2] - bounds[0];
      double contentHeight = bounds[3] - bounds[1];
      double x =
          -bounds[0] - contentWidth / 2.0 - (alignment.x * contentWidth / 2.0);
      double y = -bounds[1] -
          contentHeight / 2.0 +
          (alignment.y * contentHeight / 2.0);

      Offset renderOffset = offset;
      Size renderSize = size;

      double scaleX = 1.0, scaleY = 1.0;

      canvas.save();

      /// This widget is always set up to use [BoxFit.contain].
      /// But this behavior can be customized according to anyone's needs.
      /// The following switch/case contains all the various alternatives native to Flutter.
      switch (fit) {
        case BoxFit.fill:
          scaleX = renderSize.width / contentWidth;
          scaleY = renderSize.height / contentHeight;
          break;
        case BoxFit.contain:
          double minScale = min(renderSize.width / contentWidth,
              renderSize.height / contentHeight);
          scaleX = scaleY = minScale;
          break;
        case BoxFit.cover:
          double maxScale = max(renderSize.width / contentWidth,
              renderSize.height / contentHeight);
          scaleX = scaleY = maxScale;
          break;
        case BoxFit.fitHeight:
          double minScale = renderSize.height / contentHeight;
          scaleX = scaleY = minScale;
          break;
        case BoxFit.fitWidth:
          double minScale = renderSize.width / contentWidth;
          scaleX = scaleY = minScale;
          break;
        case BoxFit.none:
          scaleX = scaleY = 1.0;
          break;
        case BoxFit.scaleDown:
          double minScale = min(renderSize.width / contentWidth,
              renderSize.height / contentHeight);
          scaleX = scaleY = minScale < 1.0 ? minScale : 1.0;
          break;
      }

      /// 2. Move the [canvas] to the right position so that the widget's position
      /// is center-aligned based on its offset, size and alignment position.
      canvas.translate(
          renderOffset.dx +
              renderSize.width / 2.0 +
              (alignment.x * renderSize.width / 2.0),
          renderOffset.dy +
              renderSize.height / 2.0 +
              (alignment.y * renderSize.height / 2.0));
      /// 3. Scale depending on the [fit].
      canvas.scale(scaleX, scaleY);
      /// 4. Move the canvas to the correct [_flareActor] position calculated above.
      canvas.translate(x, y);
      /// 5. perform the drawing operations.
      _flareActor.draw(canvas);
      /// 6. Restore the canvas' original transform state.
      canvas.restore();
    }
    canvas.restore();
  }

  /// This callback is used by the [SchedulerBinding] in order to advance the Flare/Nima 
  /// animations properly, and update the corresponding [FlutterActor]s.
  /// It is also responsible for advancing any attached components to said Actors,
  /// such as [_nimaController] or [_flareController].
  void beginFrame(Duration timeStamp) {
    _isFrameScheduled = false;
    final double t =
        timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
    if (_lastFrameTime == 0) {
      _lastFrameTime = t;
      _isFrameScheduled = true;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
      return;
    }

    /// Calculate the elapsed time to [advance()] the animations.
    double elapsed = t - _lastFrameTime;
    _lastFrameTime = t;
    if (_timelineEntry != null) {
      TimelineAsset asset = _timelineEntry.asset;
      if (asset is TimelineNima && _nimaActor != null) {
        asset.animationTime += elapsed;

        if (asset.loop) {
          asset.animationTime %= asset.animation.duration;
        }
        /// Apply the current time to the [asset] animation.
        asset.animation.apply(asset.animationTime, _nimaActor, 1.0);
        if (_nimaController != null) {
          nima.Vec2D localTouchPosition;
          if (interactOffset != null) {
            nima.AABB bounds = asset.setupAABB;
            double contentHeight = bounds[3] - bounds[1];
            double contentWidth = bounds[2] - bounds[0];
            double x = -bounds[0] -
                contentWidth / 2.0 -
                (alignment.x * contentWidth / 2.0);
            double y = -bounds[1] -
                contentHeight / 2.0 +
                (alignment.y * contentHeight / 2.0);

            double scaleX = 1.0, scaleY = 1.0;

            switch (fit) {
              case BoxFit.fill:
                scaleX = size.width / contentWidth;
                scaleY = size.height / contentHeight;
                break;
              case BoxFit.contain:
                double minScale =
                    min(size.width / contentWidth, size.height / contentHeight);
                scaleX = scaleY = minScale;
                break;
              case BoxFit.cover:
                double maxScale =
                    max(size.width / contentWidth, size.height / contentHeight);
                scaleX = scaleY = maxScale;
                break;
              case BoxFit.fitHeight:
                double minScale = size.height / contentHeight;
                scaleX = scaleY = minScale;
                break;
              case BoxFit.fitWidth:
                double minScale = size.width / contentWidth;
                scaleX = scaleY = minScale;
                break;
              case BoxFit.none:
                scaleX = scaleY = 1.0;
                break;
              case BoxFit.scaleDown:
                double minScale =
                    min(size.width / contentWidth, size.height / contentHeight);
                scaleX = scaleY = minScale < 1.0 ? minScale : 1.0;
                break;
            }
            double dx = interactOffset.dx -
                (_renderOffset.dx +
                    size.width / 2.0 +
                    (alignment.x * size.width / 2.0));
            double dy = interactOffset.dy -
                (_renderOffset.dy +
                    size.height / 2.0 +
                    (alignment.y * size.height / 2.0));
            dx /= scaleX;
            dy /= -scaleY;
            dx -= x;
            dy -= y;

            /// Use this logic to evaluate the correct touch position that will
            /// be passed down to [NimaInteractionController.advance()].
            localTouchPosition = nima.Vec2D.fromValues(dx, dy);
          }
          /// This custom [NimaInteractionController] uses [localTouchPosition] to perform its calculations.
          _nimaController.advance(_nimaActor, localTouchPosition, elapsed);
        }
        _nimaActor.advance(elapsed);
      } else if (asset is TimelineFlare && _flareActor != null) {
        /// Some [TimelineFlare] assets have a custom intro that's played
        /// when they're painted for the first time.
        if (_firstUpdate) {
          if (asset.intro != null) {
            asset.animation = asset.intro;
            asset.animationTime = -1.0;
          }
          _firstUpdate = false;
        }
        asset.animationTime += elapsed;
        if (asset.idleAnimations != null) {
          /// If an [idleAnimation] is set up, the current time is calculated and applied to it.
          double phase = 0.0;
          for (flare.ActorAnimation animation in asset.idleAnimations) {
            animation.apply((asset.animationTime + phase) % animation.duration,
                _flareActor, 1.0);
            phase += 0.16;
          }
        } else {
          if (asset.intro == asset.animation &&
              asset.animationTime >= asset.animation.duration) {
            asset.animationTime -= asset.animation.duration;
            asset.animation = asset.idle;
          }
          if (asset.loop && asset.animationTime >= 0) {
            asset.animationTime %= asset.animation.duration;
          }
          /// Apply the current time to this [ActorAnimation].
          asset.animation.apply(asset.animationTime, _flareActor, 1.0);
        }
        if (_flareController != null) {
          flare.Vec2D localTouchPosition;
          if (interactOffset != null) {
            flare.AABB bounds = asset.setupAABB;
            double contentWidth = bounds[2] - bounds[0];
            double contentHeight = bounds[3] - bounds[1];
            double x = -bounds[0] -
                contentWidth / 2.0 -
                (alignment.x * contentWidth / 2.0);
            double y = -bounds[1] -
                contentHeight / 2.0 +
                (alignment.y * contentHeight / 2.0);

            double scaleX = 1.0, scaleY = 1.0;

            switch (fit) {
              case BoxFit.fill:
                scaleX = size.width / contentWidth;
                scaleY = size.height / contentHeight;
                break;
              case BoxFit.contain:
                double minScale =
                    min(size.width / contentWidth, size.height / contentHeight);
                scaleX = scaleY = minScale;
                break;
              case BoxFit.cover:
                double maxScale =
                    max(size.width / contentWidth, size.height / contentHeight);
                scaleX = scaleY = maxScale;
                break;
              case BoxFit.fitHeight:
                double minScale = size.height / contentHeight;
                scaleX = scaleY = minScale;
                break;
              case BoxFit.fitWidth:
                double minScale = size.width / contentWidth;
                scaleX = scaleY = minScale;
                break;
              case BoxFit.none:
                scaleX = scaleY = 1.0;
                break;
              case BoxFit.scaleDown:
                double minScale =
                    min(size.width / contentWidth, size.height / contentHeight);
                scaleX = scaleY = minScale < 1.0 ? minScale : 1.0;
                break;
            }
            double dx = interactOffset.dx -
                (_renderOffset.dx +
                    size.width / 2.0 +
                    (alignment.x * size.width / 2.0));
            double dy = interactOffset.dy -
                (_renderOffset.dy +
                    size.height / 2.0 +
                    (alignment.y * size.height / 2.0));
            dx /= scaleX;
            dy /= scaleY;
            dx -= x;
            dy -= y;
            /// Use this logic to evaluate the correct touch position that will
            /// be passed down to [FlareInteractionController.advance()].
            localTouchPosition = flare.Vec2D.fromValues(dx, dy);
          }
          /// Perform the actual [advance()]ing.
          _flareController.advance(_flareActor, localTouchPosition, elapsed);
        }
        /// Advance the [FlutterActorArtboard].
        _flareActor.advance(elapsed);
      }
    }

    /// Invalidate the current widget visual state and let Flutter paint it again.
    markNeedsPaint();
    /// Schedule a new frame to update again - but only if needed.
    if (isActive && !_isFrameScheduled) {
      _isFrameScheduled = true;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    }
  }
}
