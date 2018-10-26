import 'package:flutter/material.dart';

import "../colors.dart";

class SearchWidget extends StatefulWidget
{
    @override
    State<StatefulWidget> createState() => _SearchState();
}

class _SearchState extends State<SearchWidget>
{
    final FocusNode searchFocus = FocusNode();
    bool _isSearching = false;

    @override
    initState()
    {
        super.initState();
        searchFocus.addListener(()
        {
            setState(
                (){
                    _isSearching = searchFocus.hasFocus;
                }
            );
        });
    }

    @override
    void dispose() 
    {
        searchFocus.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) 
    {
        return Container(
            decoration: BoxDecoration(
                color: lightGrey,
                borderRadius: BorderRadius.circular(20.0)
            ),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: 
                [
                    Expanded(
                        child: Theme(
                            data: ThemeData(
                                primaryColor: darkText.withOpacity(darkText.opacity*0.5),
                            ),
                            child: TextField(
                                focusNode: searchFocus,
                                decoration: new InputDecoration(
                                    hintText: "Search",
                                    hintStyle: TextStyle(
                                        height: 18.0/16.0, // Set line to 18
                                        fontSize: 16.0,
                                        fontFamily: "Roboto",
                                        color: darkText.withOpacity(darkText.opacity*0.5),
                                    ),
                                    prefixIcon: Icon(Icons.search),
                                    suffixIcon: searchFocus.hasFocus ? IconButton(
                                        icon: Icon(Icons.cancel),
                                        onPressed: () => searchFocus.unfocus(),
                                        ) : null,
                                    border: InputBorder.none
                                ),
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontFamily: "Roboto",
                                    color: darkText.withOpacity(darkText.opacity),
                                ),
                            ),
                        ),
                    )
                ]
            )
        );
    }
}