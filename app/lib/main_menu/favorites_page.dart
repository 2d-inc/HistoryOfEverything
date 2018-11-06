import 'package:flare/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeline/main_menu/menu_data.dart';
import 'package:timeline/main_menu/thumbnail_detail_widget.dart';

import "package:timeline/colors.dart";
import "package:timeline/bloc_provider.dart";
import "package:timeline/timeline/timeline_entry.dart";
import 'package:timeline/timeline/timeline_widget.dart';

class FavoritesPage extends StatelessWidget
{
    @override
    Widget build(BuildContext context) 
    {
        List<Widget> favorites = [];
        List<TimelineEntry> entries = BlocProvider.favorites(context).favorites;

        for(int i = 0; i < entries.length; i++)
        {
            TimelineEntry entry = entries[i];
            favorites.add(ThumbnailDetailWidget(entry, hasDivider: i != 0, tapSearchResult: (TimelineEntry entry){
                MenuItemData item = MenuItemData.fromEntry(entry);
                Navigator.of(context).push(
                CupertinoPageRoute(
                    builder: (BuildContext context) => TimelineWidget(item, BlocProvider.getTimeline(context))
                    )
                );
            }));
        }
        return Scaffold(
            appBar: AppBar(
                backgroundColor: lightGrey,
                iconTheme: IconThemeData(
                    color: Colors.black.withOpacity(0.54),
                ),
                elevation: 0.0,
                centerTitle: false,
				leading: new IconButton(
					alignment: Alignment.centerLeft,
					icon: new Icon(Icons.arrow_back),
					padding: EdgeInsets.only(left:20.0, right:20.0),
					color: Colors.black.withOpacity(0.5),
					onPressed: () {
							Navigator.pop(context, true);
						},
				),
				titleSpacing: 9.0, // Note that the icon has 20 on the right due to its padding, so we add 10 to get our desired 29
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
                child: favorites.isEmpty ?
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                    [Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children:
                        [
                            Container(
                                width:128.0,
								                height:114.0,
                                margin: EdgeInsets.only(bottom: 30),
                                child: FlareActor("assets/Broken Heart.flr", animation: "Heart Break", shouldClip: false)
                            ),
                            Container(
                                padding: EdgeInsets.only(bottom: 21),
                                width:250,
                                child: Text(
                                    "You haven’t favorited anything yet.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: "RobotoMedium",
                                        fontSize: 25,
                                        color: darkText.withOpacity(darkText.opacity*0.75),
                                        height: 1.2,
                                    )
                                ),
                            ),
                            Container(
                              width:270,
                              margin: EdgeInsets.only(bottom: 114),
                                child: Text(
                                    "Browse to an event in the timeline and tap on the heart icon to save something in this list.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: "Roboto",
                                        fontSize: 17,
                                        height: 1.5,
                                        color: Colors.black.withOpacity(0.75)
                                    )
                                ),
                            ),
                        ]
                      )]
                  )
                  : 
                  ListView(children: favorites)
            )
        );
    }
}

/*
class FavoriteDetailWidget extends ThumbnailDetailWidget {
  final VoidCallback _onTap;

  FavoriteDetailWidget(TimelineEntry timelineEntry, this._onTap, {Key key})
      : super(timelineEntry, key: key);

  @override
  onTap() {
    this._onTap();
  }
}

class FavoritesPage extends StatelessWidget {
  final SelectItemCallback _onItemSelected;

  FavoritesPage(this._onItemSelected, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: lightGrey,
          iconTheme: IconThemeData(color: Colors.black.withOpacity(0.54)),
          elevation: 0.0,
          centerTitle: false,
          title: Text("Your Favorites",
              style: TextStyle(
                  fontFamily: "RobotoMedium",
                  fontSize: 20.0,
                  color: darkText.withOpacity(darkText.opacity * 0.75))),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
              children: BlocProvider.of(context)
                  .favorites
                  .map((TimelineEntry timelineEntry) {
            return FavoriteDetailWidget(timelineEntry, () {
              Navigator.of(context)
                  .pop(); // Remove the favorites page from here.
              _onItemSelected(MenuItemData.fromEntry(timelineEntry));
            });
          }).toList()),
        ));
  }
}
*/