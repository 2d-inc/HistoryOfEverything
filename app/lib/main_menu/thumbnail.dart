import "package:flutter/material.dart";

import "package:timeline/timeline/timeline_entry.dart";
import "package:timeline/article/timeline_entry_widget.dart";

/// This widget is responsible for drawing the circular thumbnail within the [ThumbnailDetailWidget].
/// 
/// It uses an inactive [TimelineEntryWidget] for the image, with a [CustomClipper] for the circular image.
class ThumbnailWidget extends StatelessWidget {
  static const double radius = 17;
  /// Reference to the entry to get the thumbnail image information.
  final TimelineEntry entry;

  ThumbnailWidget(this.entry, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TimelineAsset asset = entry.asset;
    Widget thumbnail;
    /// Check if the [entry.asset] provided is already a [TimelineImage]. 
    if (asset is TimelineImage) {
      thumbnail = RawImage(image: asset.image);
    } else if (asset is TimelineNima || asset is TimelineFlare) {
      /// If not, retrieve the image from the Nima/Flare [TimelineAsset], and set it as inactive (i.e. a static image).
      thumbnail = TimelineEntryWidget(
        isActive: false,
        timelineEntry: entry,
      );
    } else {
      thumbnail = Container(
        color: Colors.transparent,
      );
    }

    return Container(
        width: radius * 2,
        height: radius * 2,
        child: ClipPath(clipper: CircleClipper(), child: thumbnail));
  }
}

/// Custom Clipper for the desired circular effect.
class CircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..addOval(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2));
  }

  @override
  bool shouldReclip(CustomClipper<Path> old) => true;
}
