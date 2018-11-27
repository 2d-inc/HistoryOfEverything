import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:timeline/article/article_widget.dart';
import 'package:timeline/bloc_provider.dart';
import 'package:timeline/main_menu/menu_data.dart';
import 'package:timeline/timeline/timeline.dart';
import 'package:timeline/timeline/timeline_entry.dart';
import 'package:timeline/timeline/timeline_render_widget.dart';
import "package:timeline/colors.dart";
import 'package:flare/flare_actor.dart';
import 'package:video_player/video_player.dart';

class TimelineVideoWidget extends StatefulWidget {
  final Timeline timeline;
  TimelineVideoWidget(this.timeline, {Key key}) : super(key: key);

  @override
  _TimelineVideoWidgetState createState() => _TimelineVideoWidgetState();
}

class _TimelineVideoWidgetState extends State<TimelineVideoWidget>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;

  initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    animation = Tween(begin: 0.0, end: 300.0).animate(controller)
      ..addListener(() {
        setState(() {
          // the state that has changed here is the animation object’s value
        });
      });
    controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    TimelineEntry entry = widget.timeline.watchPartyEntry;
    TimelineWatchParty asset = entry?.asset;

    double rs = 0.2 + asset.scale * 0.8;
    double fitScale = 1.85;
    double w = asset.width * Timeline.AssetScreenScale * fitScale;
    double h = asset.height * Timeline.AssetScreenScale * fitScale;
    double edgePadding = -20.0 * fitScale;
    return entry != null && asset.opacity > 0
        ? Positioned.fromRect(
            rect: Rect.fromLTWH(widget.timeline.width - w - edgePadding,
                asset.y, w * rs, h * rs),
            child: Stack(children: <Widget>[
              Positioned.fill(
                  bottom: 60.0 * fitScale,
                  left: 10.0 * fitScale,
                  right: 10.0 * fitScale,
                  child:
                      Image.asset("assets/WatchParty/watching_event_tv.png")),
              Positioned.fill(
                  bottom: 60.0 * fitScale,
                  left: 10.0 * fitScale,
                  right: 10.0 * fitScale,
                  child: Container(
                      child: asset.playerController.value.size == null
                          ? null
                          : Center(
                              child: AspectRatio(
                                  aspectRatio:
                                      asset.playerController.value.aspectRatio,
                                  child:
                                      VideoPlayer(asset.playerController))))),
              Positioned.fill(
                  top: 30.0 * fitScale,
                  child: Image.asset(
                      "assets/WatchParty/watching_event_viewers.png"))
            ]))

        //Container(color: Colors.red.withOpacity(asset.opacity)))
        : Container();
  }
}
