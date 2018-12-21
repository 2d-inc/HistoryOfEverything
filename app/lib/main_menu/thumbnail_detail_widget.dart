import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeline/colors.dart';
import 'package:timeline/timeline/timeline_entry.dart';

import 'thumbnail.dart';

/// Define a custom function for the callback that's passed into this widget by the [MainMenuWidget]. 
/// 
/// This callback allows the [MainMenuWidget] to display the [TimelineWidget] and position it
/// to the right start/end time for the [entry].
typedef TapSearchResultCallback(TimelineEntry entry);

/// This widget lays out nicely the [timelineEntry] provided.
/// 
/// It shows the [ThumbnailWidget] for that entry on the left, and the label with the date of the entry
/// on its immediate right.
/// 
/// This widget is used while displaying the search results in the [MainMenuWidget], and in the
/// [FavoritesPage] widget.
class ThumbnailDetailWidget extends StatelessWidget {
  final TimelineEntry timelineEntry;
  /// Whether to show a divider line on the bottom of this widget. Defaults to `true`.
  final bool hasDivider;
  /// Callback to navigate to the timeline (see [MainMenuWidget._tapSearchResult()]).
  final TapSearchResultCallback tapSearchResult;

  ThumbnailDetailWidget(this.timelineEntry,
      {this.hasDivider = true, this.tapSearchResult, Key key})
      : super(key: key);


  /// Use [Material] & [InkWell] to show a Material Design ripple effect on the row.
  /// [InkWell] provides also a callback for custom onTap behavior.
  /// 
  /// The widget is laid out with a [Column] that lays out the contents of the entry, and the divider,
  /// and a [Row], which contains the [ThumbnailWidget], and the entry information.
  @override
  Widget build(BuildContext context) {
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
