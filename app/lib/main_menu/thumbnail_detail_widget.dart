import "package:flutter/material.dart";

import "thumbnail.dart";
import "package:timeline/colors.dart";
import "package:timeline/timeline/timeline_entry.dart";

abstract class ThumbnailDetailWidget extends StatelessWidget
{
    final TimelineEntry timelineEntry;

    ThumbnailDetailWidget(this.timelineEntry, {Key key}) : super(key:key);

    void onTap();

    @override
    Widget build(BuildContext context)
    {
        // Use (Material + InkWell) to show a ripple effect on the row.
        return Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onTap,
                child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: 
                            [
                                ThumbnailWidget(timelineEntry),
                                Container(
                                    margin: EdgeInsets.only(left: 17.0),  
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: 
                                        [
                                            Text(timelineEntry.label,
                                                style: TextStyle(
                                                    fontFamily: "RobotoMedium",
                                                    fontSize: 20.0,
                                                    color: darkText.withOpacity(darkText.opacity*0.75)
                                                )
                                            ,),
                                            Text(timelineEntry.formatYearsAgo(),
                                                style: TextStyle(
                                                    fontFamily: "Roboto",
                                                    fontSize: 14.0,
                                                    color: Colors.black.withOpacity(0.5)
                                                )
                                            )
                                        ]
                                    ),
                                )
                            ],
                        ),
                    ),
            )
        );
    }
}