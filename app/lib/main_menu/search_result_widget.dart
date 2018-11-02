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
        double start = timelineEntry.start;
        double end = (timelineEntry.type == TimelineEntryType.Era) ? timelineEntry.start : timelineEntry.end;
        if(start == end)
        {
            // Use 2.5% of the current timeline entry date to estimate start/end.
            double distance = start * 0.025;
            start += distance;
            end -= distance;
        }
        this._onSelected(MenuItemData.fromData(timelineEntry.label, start, end));
    }
}