import 'package:flutter/material.dart';

import "package:timeline/colors.dart";

class SearchWidget extends StatefulWidget
{
    final FocusNode _searchFocusNode;
    final TextEditingController _searchController;

    SearchWidget(this._searchFocusNode, this._searchController, {Key key}) : super(key: key);

    @override
    State<StatefulWidget> createState() => _SearchState();
}

class _SearchState extends State<SearchWidget>
{
    @override
    Widget build(BuildContext context) 
    {
        return Container(
				decoration: BoxDecoration(
                color: lightGrey,
                borderRadius: BorderRadius.circular(24.0),
            ),
            height: 40.0,
            child: Theme(
					data: ThemeData(
						primaryColor: darkText.withOpacity(darkText.opacity*0.5),
					),
					child: TextField(
						controller: widget._searchController,
						focusNode: widget._searchFocusNode,
						decoration: new InputDecoration(
							hintText: "Search",
							hintStyle: TextStyle(
								fontSize: 16.0,
								fontFamily: "Roboto",
								color: darkText.withOpacity(darkText.opacity*0.5),
							),
							prefixIcon: Icon(Icons.search),
							suffixIcon: widget._searchFocusNode.hasFocus ? IconButton(
								icon: Icon(Icons.cancel),
								onPressed: () {
									widget._searchFocusNode.unfocus();
									widget._searchController.clear();
								}) : null,
							border: InputBorder.none
						),
						style: TextStyle(
							fontSize: 16.0,
							fontFamily: "Roboto",
							color: darkText.withOpacity(darkText.opacity),
						),
					),
				),
			);
    }
}