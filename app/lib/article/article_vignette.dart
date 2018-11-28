import 'dart:math';

import 'package:flare/flare/math/mat2d.dart';
import 'package:flare/flare/math/transform_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:timeline/timeline/timeline_entry.dart';

import '../article/timeline_entry_widget.dart';

class ArticleVignette extends StatefulWidget {
  final TimelineEntry article;
  final Offset interactOffset;
  ArticleVignette({this.article, this.interactOffset, Key key})
      : super(key: key);

  @override
  _ArticleVignetteState createState() => _ArticleVignetteState();
}

class _ArticleVignetteState extends State<ArticleVignette> {
  GoogleMapController mapController;
  Rect mapRect;
  Matrix4 mapTransform;
  static const double MapPixelDensity = 3.0;

  initState() {
    super.initState();
    mapRect =
        Rect.fromLTWH(0.0, 0.0, 44.0 * MapPixelDensity, 94.0 * MapPixelDensity);
    mapTransform = Matrix4.translationValues(-1000.0, -1000.0, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    TimelineAsset asset = widget.article?.asset;
    if (asset is TimelineFlare && asset.mapNode != null) {
      return Stack(overflow: Overflow.visible, children: <Widget>[
        Positioned.fill(
            child: TimelineEntryWidget(
                isActive: true,
                timelineEntry: widget.article,
                interactOffset: widget.interactOffset,
                updateMapNode: (Mat2D screenTransform, Mat2D transform) {
                  TransformComponents components = TransformComponents();
                  Mat2D.decompose(transform, components);
                  setState(() {
                    // final RenderBox renderBox = context.findRenderObject();
                    // final position = renderBox.localToGlobal(Offset.zero);
                    //mapTransform = Matrix4.fromFloat64List(transform.mat4);
                    //* Matrix4.translationValues(-mapRect.width/2.0, -mapRect.height/2.0, 0.0)
                    //ffset(20.0, 78.3)
                    // 40, 80
                    Mat2D scale = Mat2D();
                    scale[0] = 1.0 / MapPixelDensity;
                    scale[3] = 1.0 / MapPixelDensity;

                    mapTransform = Matrix4.fromFloat64List(
                            screenTransform.mat4) *
                        Matrix4.fromFloat64List(transform.mat4) *
                        Matrix4.translationValues(-22.0, -45, 0.0) *
                        Matrix4.fromFloat64List(scale.mat4) *
                        Matrix4.translationValues(
                            mapRect.width / 2.0, mapRect.height / 2.0, 0.0) *
                        Matrix4.rotationZ(pi / 2.0 - 0.015) *
                        Matrix4.translationValues(
                            -mapRect.width / 2.0, -mapRect.height / 2.0, 0.0);
                  });
                })),
        Positioned.fromRect(
            rect: mapRect,
            child: Transform(
                alignment: Alignment.topLeft,
                transform:
                    mapTransform, //Matrix4.skewY(0.3)..rotateZ(-math.pi / 12.0),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.0),
                    child: GoogleMap(
                      options: GoogleMapOptions(
                        cameraPosition: const CameraPosition(
                          bearing: 270.0,
                          target: LatLng(51.5160895, -0.1294527),
                          tilt: 30.0,
                          zoom: 7.0,
                        ),
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        mapController = controller;
                      },
                    ))))
      ]);
    }
    return TimelineEntryWidget(
        isActive: true,
        timelineEntry: widget.article,
        interactOffset: widget.interactOffset);
  }
}
