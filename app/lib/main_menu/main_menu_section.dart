import 'package:flutter/material.dart';

import "../colors.dart";

class MenuSection extends StatefulWidget
{
    final String title;
    final Color backgroundColor;
    final Color accentColor;

    MenuSection(this.title, this.backgroundColor, this.accentColor, {Key key}) : super(key: key);

    @override
    State<StatefulWidget> createState() => _SectionState();
}

class _SectionState extends State<MenuSection> 
{
    @override
    Widget build(BuildContext context) {
        return Container(
            height: 150.0,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: widget.backgroundColor
            ),
            child:Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: 
                [
                    Expanded(
                        child: Row(
                            children:
                            [
                                Container(
                                    height: 20.0,
                                    width: 20.0,
                                    color: widget.accentColor,
                                    margin: EdgeInsets.all(18.0)
                                ),
                                Text(
                                    widget.title,
                                    style: TextStyle(
                                        fontSize: 20.0,
                                        fontFamily: "RobotoMedium",
                                        color: widget.accentColor
                                    ),
                                )
                            ],
                        )
                    )
                ]
            )
        );
    }
}