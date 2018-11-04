import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";
import 'package:timeline/bloc_provider.dart';
import 'package:timeline/main_menu/menu_data.dart';
import 'package:timeline/timeline/timeline_widget.dart';

import "thumbnail.dart";
import "package:timeline/colors.dart";
import "package:timeline/timeline/timeline_entry.dart";

class ThumbnailDetailWidget extends StatelessWidget
{
    final TimelineEntry timelineEntry;
    final bool hasDivider;

    ThumbnailDetailWidget(this.timelineEntry, {this.hasDivider = true, Key key}) : super(key:key);

    @override
    Widget build(BuildContext context)
    {
        // Use (Material + InkWell) to show a ripple effect on the row.
        return Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: ()
                {
                    MenuItemData item = MenuItemData.fromEntry(timelineEntry);
                    Navigator.of(context).push(
                        CupertinoPageRoute(
                            builder: (BuildContext context) => TimelineWidget(item, BlocProvider.getTimeline(context))
                        )
                    );
                },
                child: Column(
                    children: <Widget>[
                        hasDivider ? 
                        Container(
                            height: 1,
                            color: const Color.fromRGBO(151, 151, 151, 0.29)
                        )
                        : Container(),
                        Padding(
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
                    ],
                ),
            )
        );
    }
}