import 'package:flutter/material.dart';

import "../colors.dart";

class SearchWidget extends StatelessWidget
{
    @override
    Widget build(BuildContext context) 
    {
        return FlatButton(
                    onPressed: () => print("TAP"), // TODO: implement search view.
                    color: lightGrey,
                    shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(20.0)),
                    child: Row(
                        children: 
                        [
                            Container(
                                margin: EdgeInsets.only(left:20.0, right:15.0),
                                height:17.5,
                                width: 17.5,
                                color: darkText
                                ),
                                Text(
                                    "Type to search...",
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        fontFamily: "Roboto",
                                        color: darkText.withOpacity(darkText.opacity*0.5),
                                    ),
                                )
                        ]
                    )
                );
    }
}