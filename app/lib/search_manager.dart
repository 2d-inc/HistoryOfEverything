import "dart:collection";

import "timeline/timeline_entry.dart";

class SearchManager
{
    static final SearchManager _searchManager = new SearchManager._internal();
    final SplayTreeMap<String, Set<TimelineEntry>> _queryMap = new SplayTreeMap<String, Set<TimelineEntry>>();

    SearchManager._internal();

    _fill(List<TimelineEntry> entries)
    {
        _queryMap.clear(); // Cleanup.

        // Fill the map with all the search substrings.
        for(TimelineEntry e in entries)
        {
            String label = e.label;
            int len = label.length;
            for(int i = 0; i < len; i++)
            {
                for(int j = i+1; j <= len; j++)
                {
                    String substring = label.substring(i, j).toLowerCase();
                    if(_queryMap.containsKey(substring))
                    {
                        Set<TimelineEntry> labels = _queryMap[substring];
                        labels.add(e);
                    }
                    else
                    {
                        _queryMap.putIfAbsent(substring, () => new Set.from([e]));
                    }
                }
            }
        }
    }

    factory SearchManager.init([List<TimelineEntry> entries])
    {
        if(entries != null)
        {
            _searchManager._fill(entries);
        }
        return _searchManager;
    }

    Set<TimelineEntry> performSearch(String query)
    {
        if(_queryMap.containsKey(query))
            return _queryMap[query];
        Iterable<String> keys = _queryMap.keys;
        Set<TimelineEntry> res = Set();
        for(String k in keys)
        {
            res.addAll(_queryMap[k]);
        }
        return res;
    }
}