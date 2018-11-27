import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";

import "thumbnail.dart";
import "package:timeline/colors.dart";
import "package:timeline/timeline/timeline_entry.dart";

typedef TapSearchResultCallback(TimelineEntry entry);

class ThumbnailDetailWidget extends StatelessWidget {
  final TimelineEntry timelineEntry;
  final bool hasDivider;
  final TapSearchResultCallback tapSearchResult;

  ThumbnailDetailWidget(this.timelineEntry,
      {this.hasDivider = true, this.tapSearchResult, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use (Material + InkWell) to show a ripple effect on the row.
    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (tapSearchResult != null) {
              tapSearchResult(timelineEntry);
            }
          },
          child: Column(
            children: <Widget>[
              hasDivider
                  ? Container(
                      height: 1,
                      color: const Color.fromRGBO(151, 151, 151, 0.29))
                  : Container(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ThumbnailWidget(timelineEntry),
                    Expanded(
                        child: Container(
                      margin: EdgeInsets.only(left: 17.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timelineEntry.label,
                              style: TextStyle(
                                  fontFamily: "RobotoMedium",
                                  fontSize: 20.0,
                                  color: darkText
                                      .withOpacity(darkText.opacity * 0.75)),
                            ),
                            Text(timelineEntry.formatYearsAgo(),
                                style: TextStyle(
                                    fontFamily: "Roboto",
                                    fontSize: 14.0,
                                    color: Colors.black.withOpacity(0.5)))
                          ]),
                    ))
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
