import "package:flutter/material.dart";

import "menu_data.dart";
import "main_menu_section.dart";
import "search_result_widget.dart";
import "thumbnail_detail_widget.dart";
import "../colors.dart";
import "../blocs/favorites_bloc.dart";
import "../timeline/timeline_entry.dart";


class FavoritesPage extends StatefulWidget
{
    final SelectItemCallback onSelected;

    FavoritesPage(this.onSelected);

    @override
    State<StatefulWidget> createState() => _FavoritesState();
}

class _FavoritesState extends State<FavoritesPage>
{    
    List<TimelineEntry> _favorites = [];

    @override
    initState()
    {
        super.initState();
    }

    @override
    Widget build(BuildContext context) 
    {
        FavoritesBloc bloc = FavoritesBloc();
        bloc.fetchFavorites().then((List<TimelineEntry> favs)
        {
            _favorites.clear();
            setState(
                () {
                    _favorites = favs;
                }
            );
        });
        
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
                    children: _favorites.map(
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
                                widget.onSelected(MenuItemData.fromData(te.label, start, end));
                            });
                        }).toList()
                ),
            )
        );
  }
}

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