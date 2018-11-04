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

    ThumbnailDetailWidget(this.timelineEntry, {Key key}) : super(key:key);

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
                        PageRouteBuilder(
                                opaque: true,
                                transitionDuration: const Duration(milliseconds: 300),
                                pageBuilder: (context, _, __) => TimelineWidget(item, BlocProvider.getTimeline(context)),
                                transitionsBuilder: (_, Animation<double> animation, __, Widget child)
                                {
                                    return new SlideTransition(
                                        child: child,
                                        position: new Tween<Offset>(
                                            begin: const Offset(1.0, 0.0),
                                            end: Offset.zero
                                        ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.fastOutSlowIn
                                        ))
                                    );
                                }
                            )
                    );
                },
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