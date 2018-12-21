import 'package:flutter/material.dart';

import "package:timeline/colors.dart";

/// Draws the search bar on top of the menu.
class SearchWidget extends StatelessWidget {

  /// These two fields are passed down from the [MainMenuWidget] in order to control 
  /// the state of this widget depending on the users' inputs.
  final FocusNode _searchFocusNode;
  final TextEditingController _searchController;

  SearchWidget(this._searchFocusNode, this._searchController, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// Custom implementation of the Cupertino Search bar:
    /// a rounded rectangle with the search prefix icon on the left and the 
    /// cancel icon on the right only when the widget is focused.
    /// The [TextField] displays a hint when no text has been input,
    /// and it updates the [_searchController] so that the [MainMenuWidget] can 
    /// update the list of results underneath this widget.
    return Container(
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(24.0),
      ),
      height: 40.0,
      child: Theme(
        data: ThemeData(
          primaryColor: darkText.withOpacity(darkText.opacity * 0.5),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
              hintText: "Search",
              hintStyle: TextStyle(
                fontSize: 16.0,
                fontFamily: "Roboto",
                color: darkText.withOpacity(darkText.opacity * 0.5)
              ),
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchFocusNode.hasFocus
                  ? IconButton(
                      icon: Icon(Icons.cancel),
                      onPressed: () {
                        _searchFocusNode.unfocus();
                        _searchController.clear();
                      })
                  : null,
              border: InputBorder.none),
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
