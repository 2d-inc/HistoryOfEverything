import "dart:collection";
import "dart:convert";

import "package:flutter/services.dart" show rootBundle;

class SearchManager
{
    static final SearchManager _searchManager = new SearchManager._internal();
    final SplayTreeMap<String, Set<SearchResult>> _queryMap = new SplayTreeMap<String, Set<SearchResult>>();

    List<SearchResult> labels;

    SearchManager._internal()
    {
        labels = [];
        _loadFromBundle("assets/timeline.json").then((bool success)
        {
            print("Processed all the entries! $labels");
        });
    }

    Future<bool> _loadFromBundle(String filepath) async
    {
        String data = await rootBundle.loadString(filepath);
        List jsonEntries = json.decode(data) as List;

        for(dynamic entry in jsonEntries)
        {
            Map map = entry as Map;

            if(map != null)
            {
                String label;
                int startTime;
                if(map.containsKey("label"))
                {
                    label = map["label"] as String;
                }
                if(map.containsKey("date"))
                {
                    num start = map["date"];
                    startTime = start.toInt();
                }
                else if(map.containsKey("start"))
                {
                    num start = map["start"];
                    startTime = start.toInt();
                }

                SearchResult sr = new SearchResult(label, startTime);
                labels.add(sr);
                // Add to the map all the substrings of this label, to perform a search more efficiently.
                int len = label.length;
                for(int i = 0; i < len; i++)
                {
                    for(int j = i+1; j <= len; j++)
                    {
                        String substring = label.substring(i, j).toLowerCase();
                        if(_queryMap.containsKey(substring))
                        {
                            Set<SearchResult> labels = _queryMap[substring];
                            labels.add(sr);
                        }
                        else
                        {
                            _queryMap.putIfAbsent(substring, () => new Set.from([sr]));
                        }
                    }
                }
            }
        }
        for(MapEntry<String, Set<SearchResult>> entry in _queryMap.entries)
        {
            print("${entry.key}, ${entry.value}");
        }
        return true;
    }

    factory SearchManager()
    {
        return _searchManager;
    }

    Set<SearchResult> performSearch(String query)
    {
        if(_queryMap.containsKey(query))
            return _queryMap[query];
        return Set();
    }
}


class SearchResult
{
    final String label;
    final int startTime;
    // TODO: final String imagePath;
    SearchResult(this.label, this.startTime);

    String formatYearsAgo()
    {
        String label;
        int valueAbs = startTime.abs();
        if(valueAbs > 1000000000)
        {
            double v = (valueAbs/100000000.0).floorToDouble()/10.0;
            
            label = (valueAbs/1000000000).toStringAsFixed(v == v.floorToDouble() ? 0 : 1) + " Billion";
        }
        else if(valueAbs > 1000000)
        {
            double v = (valueAbs/100000.0).floorToDouble()/10.0;
            label = (valueAbs/1000000).toStringAsFixed(v == v.floorToDouble() ? 0 : 1) + " Million";
        }
        else if(valueAbs > 10000) // N.B. < 10,000
        {
            double v = (valueAbs/100.0).floorToDouble()/10.0;
            label = (valueAbs/1000).toStringAsFixed(v == v.floorToDouble() ? 0 : 1) + " Thousand";
        }
        else
        {
            label = valueAbs.toStringAsFixed(0) + " Years Ago";
        }
        return "$label Years Ago";
    }

    @override
    String toString()
    {
        return "$label: $startTime";
    }
}