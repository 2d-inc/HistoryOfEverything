import "package:flutter/material.dart";

import "package:timeline/timeline/timeline_entry.dart";
import "package:timeline/article/timeline_entry_widget.dart";

class ThumbnailWidget extends StatelessWidget
{
    final TimelineEntry entry;
    final double radius;

    ThumbnailWidget(this.entry, {this.radius = 17, Key key}) : super(key:key);

    @override
    Widget build(BuildContext context)
    {
        TimelineAsset asset = entry.asset;
        Widget thumbnail;
        if(asset is TimelineImage)
        {
            thumbnail = RawImage(image: asset.image);
        }
        else if(asset is TimelineNima || asset is TimelineFlare)
        {
            thumbnail = TimelineEntryWidget(
                isActive: false,
                timelineEntry: entry,
            );
        }
        else
        {
            thumbnail = Container(
                color: Colors.blueAccent,
            );
        }

        return Container(
            width: radius*2,
            height: radius*2,
            child: ClipPath(
                clipper: CircleClipper(),
                child: thumbnail
            )
        );
    }
}

class CircleClipper extends CustomClipper<Path>
{
    @override
    Path getClip(Size size)
    {
        return Path()
            ..addOval(
                Rect.fromCircle(
                    center: Offset(size.width/2, size.height/2),
                    radius: size.width/2
                )
            );
    }

    @override
    bool shouldReclip(CustomClipper<Path> old) => true;
}