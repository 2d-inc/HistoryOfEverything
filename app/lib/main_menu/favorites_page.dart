import "package:flutter/material.dart";
import 'package:timeline/main_menu/thumbnail_detail_widget.dart';

import "package:timeline/colors.dart";
import "package:timeline/bloc_provider.dart";
import "package:timeline/timeline/timeline_entry.dart";

class FavoritesPage extends StatelessWidget
{
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
                    children: BlocProvider.favorites(context).favorites.map(
                        (TimelineEntry te) => ThumbnailDetailWidget(te)
                    ).toList()
                ),
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