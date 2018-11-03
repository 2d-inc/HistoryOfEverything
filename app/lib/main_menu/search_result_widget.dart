import "package:flutter/services.dart";
import "package:flutter/material.dart";

import "thumbnail_detail_widget.dart";
import "menu_data.dart";
import "main_menu_section.dart";
import "package:timeline/timeline/timeline_entry.dart";

class SearchResultWidget extends ThumbnailDetailWidget
{
    final SelectItemCallback _onSelected;

    SearchResultWidget(this._onSelected, TimelineEntry timelineEntry, {Key key}) : super(timelineEntry, key:key);

    @override
    onTap()
    {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        this._onSelected(MenuItemData.fromEntry(timelineEntry));
    }
}