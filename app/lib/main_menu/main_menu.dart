import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import "./search_widget.dart";
import "./main_menu_section.dart";
import "../colors.dart";

class MainMenuWidget extends StatelessWidget
{
    @override
    Widget build(BuildContext context) 
    {
        return Container(
            color: background,
            child: Container(
                margin: EdgeInsets.only(top: 35.0, left: 20.0, right: 20.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: 
                    [
                        Row(
                            children:
                            [
                                Container( // TODO: replace this with the Flutter logo.
                                    color: darkText,
                                    height: 22.0,
                                    width: 22.0
                                ),
                                Container(
                                    margin: EdgeInsets.only(left: 10.0),
                                    child: Text(
                                        "Flutter Presents",
                                        style: TextStyle(
                                            color: darkText.withOpacity(darkText.opacity*0.75),
                                            fontSize: 16.0,
                                            fontFamily: "Roboto"
                                            )
                                    )
                                )
                            ]),
                            Container(
                                // color: Color.fromRGBO(0, 0, 0, 1.0),
                                margin: EdgeInsets.only(top: 14.0, bottom: 22.0),
                                child: Text(
                                    "The History & Future\nof Everything",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                            color: darkText.withOpacity(darkText.opacity*0.75),
                                            fontSize: 34.0,
                                            fontFamily: "RobotoMedium"
                                        )
                                    )
                            ),
                            SearchWidget(),
                            Container(
                                margin: EdgeInsets.only(top: 20.0),
                                child: MenuSection(
                                    "Birth of the Universe", 
                                    Color.fromRGBO(8, 49, 88, 1.0),
                                    lightText
                                )
                            ),
                            Container(
                                margin: EdgeInsets.only(top: 20.0),
                                child: MenuSection(
                                    "Life on Earth", 
                                    Colors.white,
                                    Colors.black
                                )
                            ),
                            Container(
                                margin: EdgeInsets.only(top: 20.0),
                                child: MenuSection(
                                    "The Future", 
                                    Color.fromRGBO(0, 29, 34, 1.0),
                                    lightText
                                )
                            ),
                    ]
                )
            )
        );
    }

}