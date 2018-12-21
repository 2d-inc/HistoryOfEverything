import 'dart:collection';

import 'package:timeline/timeline/timeline_entry.dart';

/// This object handles the search operation in the app. When it is initialized,
/// receiving the full list of entries as input, the object fills in a [SplayTreeMap],
/// i.e. a self-balancing binary tree. 
class SearchManager {
  static final SearchManager _searchManager = SearchManager._internal();
  /// This map creates a dictionary for every possible substring that each of the
  /// [TimelineEntry] labels have, and uses a [Set] as a value, allowing for multiple
  /// entires to be stored for a single key.
  final SplayTreeMap<String, Set<TimelineEntry>> _queryMap =
      SplayTreeMap<String, Set<TimelineEntry>>();

  /// Constructor definition.
  SearchManager._internal();

  /// Factory constructor that will perform the initialization, and return the reference
  /// the _searchManager (constructing it if called a first time.).
  factory SearchManager.init([List<TimelineEntry> entries]) {
    if (entries != null) {
      _searchManager._fill(entries);
    }
    return _searchManager;
  }

  _fill(List<TimelineEntry> entries) {
    /// Sanity check.
    _queryMap.clear(); 

    /// Fill the map with all the possible searchable substrings. 
    /// This operation is O(n^2), thus very slow, and performed only once upon initialization.
    for (TimelineEntry e in entries) {
      String label = e.label;
      int len = label.length;
      for (int i = 0; i < len; i++) {
        for (int j = i + 1; j <= len; j++) {
          String substring = label.substring(i, j).toLowerCase();
          if (_queryMap.containsKey(substring)) {
            Set<TimelineEntry> labels = _queryMap[substring];
            labels.add(e);
          } else {
            _queryMap.putIfAbsent(substring, () => Set.from([e]));
          }
        }
      }
    }
  }

  /// Use the [SplayTreeMap] query function to return the full [Set] of results.
  /// This operation amortized logarithmic time.
  Set<TimelineEntry> performSearch(String query) {
    if (_queryMap.containsKey(query))
      return _queryMap[query];
    else if (query.isNotEmpty) {
      return Set();
    }
    Iterable<String> keys = _queryMap.keys;
    Set<TimelineEntry> res = Set();
    for (String k in keys) {
      res.addAll(_queryMap[k]);
    }
    return res;
  }
}
