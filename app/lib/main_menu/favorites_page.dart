import "package:flutter/material.dart";

import "menu_data.dart";
import "main_menu_section.dart";
import "thumbnail_detail_widget.dart";
import "package:timeline/colors.dart";
import "package:timeline/bloc_provider.dart";
import "package:timeline/timeline/timeline_entry.dart";

class FavoriteDetailWidget extends ThumbnailDetailWidget
{
    final VoidCallback _onTap;

    FavoriteDetailWidget(TimelineEntry timelineEntry, this._onTap, {Key key}) : super(timelineEntry, key:key);

    @override
    onTap()
    {
        this._onTap();
    }
}

class FavoritesPage extends StatelessWidget
{    
    final SelectItemCallback _onItemSelected;

    FavoritesPage(this._onItemSelected, {Key key}) : super(key:key);

    @override
    Widget build(BuildContext context) 
    {        
        return Scaffold(
            appBar: AppBar(
                backgroundColor: lightGrey,
                iconTheme: IconThemeData(
                    color: Colors.black.withOpacity(0.54)
                ),
                elevation: 0.0,
                centerTitle: false,
                title: Text(
                    "Your Favorites",
                    style: TextStyle(
                        fontFamily: "RobotoMedium",
                        fontSize: 20.0,
                        color: darkText.withOpacity(darkText.opacity * 0.75)
                    )
                    ),
            ),
            body: Padding(
                padding: const EdgeInsets.symmetric(horizontal:20.0),
                child: ListView(
                    children: BlocProvider.of(context).favorites.map(
                        (TimelineEntry te) {
                            return FavoriteDetailWidget(te, ()
                            {
                                Navigator.of(context).pop(); // Remove the favorites page from here.
                                double start = te.start;
                                double end = (te.type == TimelineEntryType.Era) ? te.start : te.end;
                                if(start == end)
                                {
                                    // Use 2.5% of the current timeline entry date to estimate start/end.
                                    double distance = start * 0.025;
                                    start += distance;
                                    end -= distance;
                                }
                                _onItemSelected(MenuItemData.fromData(te.label, start, end));
                            });
                        }).toList()
                ),
            )
        );
    }
}