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