import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flare/flare/actor_image.dart' as flare;
import 'package:flare/flare/math/aabb.dart' as flare;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:nima/nima/actor_image.dart' as nima;
import 'package:nima/nima/math/aabb.dart' as nima;
import 'package:timeline/bloc_provider.dart';
import 'package:timeline/timeline/timeline.dart';
import 'package:timeline/timeline/timeline_entry.dart';

/// This widget renders a Flare/Nima [FlutterActor]. It relies on a [LeafRenderObjectWidget] 
/// so it can implement a custom [RenderObject] and update it accordingly.
class MenuVignette extends LeafRenderObjectWidget {
  /// A flag is used to animate the widget only when needed.
  final bool isActive;
  /// The id of the [FlutterActor] that will be rendered.
  final String assetId;
  /// A gradient color to give the section background a faded look. 
  /// Also makes the sub-section more readable.
  final Color gradientColor;

  MenuVignette({Key key, this.gradientColor, this.isActive, this.assetId})
      : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    /// The [BlocProvider] widgets down the tree to access its components
    /// optimizing memory consumption and simplifying the code-base.
    Timeline t = BlocProvider.getTimeline(context);
    return MenuVignetteRenderObject()
      ..timeline = t
      ..assetId = assetId
      ..gradientColor = gradientColor
      ..isActive = isActive;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant MenuVignetteRenderObject renderObject) {
    /// The [BlocProvider] widgets down the tree to access its components
    /// optimizing memory consumption and simplifying the code-base.
    Timeline t = BlocProvider.getTimeline(context);
    renderObject
      ..timeline = t
      ..assetId = assetId
      ..gradientColor = gradientColor
      ..isActive = isActive;
  }

  @override
  didUnmountRenderObject(covariant MenuVignetteRenderObject renderObject) {
    renderObject.isActive = false;
  }
}

/// When extending a [RenderBox] we provide a custom set of instructions for the widget being rendered.
/// 
/// In particular this means overriding the [paint()] and [hitTestSelf()] methods to render the loaded
/// Flare/Nima [FlutterActor] where the widget is being placed.
class MenuVignetteRenderObject extends RenderBox {
  /// The [_timeline] object is used here to retrieve the asset through [getById()].
  Timeline _timeline;
  String _assetId;
  /// If this object is not active, stop playing. This optimizes resource consumption
  /// and makes sure that each [FlutterActor] remains coherent throughout its animation.
  bool _isActive = false;
  bool _firstUpdate = true;
  double _lastFrameTime = 0.0;
  Color gradientColor;
  bool _isFrameScheduled = false;
  double opacity = 0.0;

  Timeline get timeline => _timeline;
  set timeline(Timeline value) {
    if (_timeline == value) {
      return;
    }
    _timeline = value;
    _firstUpdate = true;
    updateRendering();
  }

  set assetId(String id) {
    if (_assetId != id) {
      _assetId = id;
      updateRendering();
    }
  }

  bool get isActive => _isActive;
  set isActive(bool value) {
    if (_isActive == value) {
      return;
    }
    /// When this [RenderBox] becomes active, start advancing it again.
    _isActive = value;
    updateRendering();
  }

  TimelineEntry get timelineEntry {
    if (_timeline == null) {
      return null;
    }
    return _timeline.getById(_assetId);
  }

  @override
  bool get sizedByParent => true;

  @override
  bool hitTestSelf(Offset screenOffset) => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  /// Uses the [SchedulerBinding] to trigger a new paint for this widget.
  void updateRendering() {
    if (_isActive) {
      markNeedsPaint();
      if (!_isFrameScheduled) {
        _isFrameScheduled = true;
        SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
      }
    }
    markNeedsLayout();
  }

  /// This overridden method is where we can implement our custom drawing logic, for
  /// laying out the [FlutterActor], and drawing it to [canvas].
  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    TimelineAsset asset = timelineEntry?.asset;

    /// Don't paint if not needed.
    if (asset == null) {
      opacity = 0.0;
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
    } else if (asset is TimelineNima && asset.actor != null) {
      Alignment alignment = Alignment.topRight;
      BoxFit fit = BoxFit.cover;

      /// If we have a [TimelineNima] actor set it up properly and paint it.
      
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

      /// This widget is always set up to use [BoxFit.cover].
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
      asset.actor.draw(canvas, 1.0);

      /// 6. Restore the canvas' original transform state.
      canvas.restore();


      /// 7. Use the [gradientColor] field to customize the foreground element being rendered,
      /// and cover it with a linear gradient.
      double gradientFade = 1.0 - opacity;
      List<ui.Color> colors = <ui.Color>[
        gradientColor.withOpacity(gradientFade),
        gradientColor.withOpacity(min(1.0, gradientFade + 0.9))
      ];
      List<double> stops = <double>[0.0, 1.0];

      ui.Paint paint = ui.Paint()
        ..shader = ui.Gradient.linear(ui.Offset(0.0, offset.dy),
            ui.Offset(0.0, offset.dy + 150.0), colors, stops)
        ..style = ui.PaintingStyle.fill;
      canvas.drawRect(offset & size, paint);
    } else if (asset is TimelineFlare && asset.actor != null) {
      Alignment alignment = Alignment.center;
      BoxFit fit = BoxFit.cover;
      /// If we have a [TimelineFlare]  actor set it up properly and paint it.
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

      /// This widget is always set up to use [BoxFit.cover].
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
      asset.actor.draw(canvas);

      /// 6. Restore the canvas' original transform state.
      canvas.restore();

      /// 7. Use the [gradientColor] field to customize the foreground element being rendered,
      /// and cover it with a linear gradient.
      double gradientFade = 1.0 - opacity;
      List<ui.Color> colors = <ui.Color>[
        gradientColor.withOpacity(gradientFade),
        gradientColor.withOpacity(min(1.0, gradientFade + 0.9))
      ];
      List<double> stops = <double>[0.0, 1.0];

      ui.Paint paint = ui.Paint()
        ..shader = ui.Gradient.linear(ui.Offset(0.0, offset.dy),
            ui.Offset(0.0, offset.dy + 150.0), colors, stops)
        ..style = ui.PaintingStyle.fill;
      canvas.drawRect(offset & size, paint);
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
      _isFrameScheduled = true;
      _lastFrameTime = t;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
      return;
    }

    /// Calculate the elapsed time to [advance()] the animations.
    double elapsed = t - _lastFrameTime;
    _lastFrameTime = t;
    TimelineEntry entry = timelineEntry;
    if (entry != null) {
      TimelineAsset asset = entry.asset;
      if (asset is TimelineNima && asset.actor != null) {
        /// Modulate the opacity value used by [gradientFade].
        if (opacity < 1.0) {
          opacity = min(opacity + elapsed, 1.0);
        }
        asset.animationTime += elapsed;
        if (asset.loop) {
          asset.animationTime %= asset.animation.duration;
        }
        /// Apply the current time to the [asset] animation.
        asset.animation.apply(asset.animationTime, asset.actor, 1.0);
        /// Use the library function to update the actor's time.
        asset.actor.advance(elapsed);
      } else if (asset is TimelineFlare && asset.actor != null) {
        if (opacity < 1.0) {
          /// Modulate the opacity value used by [gradientFade].
          opacity = min(opacity + elapsed, 1.0);
        }
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
        if (asset.intro == asset.animation &&
            asset.animationTime >= asset.animation.duration) {
          asset.animationTime -= asset.animation.duration;
          asset.animation = asset.idle;
        }
        if (asset.loop && asset.animationTime >= 0) {
          asset.animationTime %= asset.animation.duration;
        }
        /// Apply the current time to this [ActorAnimation].
        asset.animation.apply(asset.animationTime, asset.actor, 1.0);
        /// Use the library function to update the actor's time.
        asset.actor.advance(elapsed);
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
