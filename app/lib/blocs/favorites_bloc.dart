import "package:shared_preferences/shared_preferences.dart";

import "package:timeline/timeline/timeline_entry.dart";

/// Stores the logic for handling favorites throughout the app.
/// Relies on the shared_preferences Flutter library to persist app data
/// and retrieve it upon restart.
/// This library interfaces correctly with both iOS & Android for full platform 
/// independence. 
/// It's available at: https://pub.dartlang.org/packages/shared_preferences
class FavoritesBloc {
  static const String FAVORITES_KEY = "Favorites";
  final List<TimelineEntry> _favorites = [];

  /// This method is called during the [BlocProvider] initialization.
  /// It receives as input the full list of [TimelineEntry], so that it can
  /// use those references to fill [_favorites].
  init(List<TimelineEntry> entries) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList(FavoritesBloc.FAVORITES_KEY);
    /// A [Map] is used to optimize retrieval times when checking if a favorite
    /// is already present - in fact the label's used as the key.
    /// Checking if an element is in the map is O(1), making this process O(n)
    /// with n entries.
    Map<String, TimelineEntry> entriesMap = Map();
    for (TimelineEntry e in entries) {
      entriesMap.putIfAbsent(e.label, () => e);
    }
    if (favs != null) {
      for (String f in favs) {
        TimelineEntry entry = entriesMap[f];
        if (entry != null) {
          _favorites.add(entry);
        }
      }
    }
    /// Sort by starting time, so the favorites' list is always displayed in ascending order.
    _favorites.sort((TimelineEntry a, TimelineEntry b) {
      return a.start.compareTo(b.start);
    });
  }

  List<TimelineEntry> get favorites {
    return _favorites;
  }

  /// Save [e] into the list, re-sort it, and store to disk.
  addFavorite(TimelineEntry e) {
    if (!_favorites.contains(e)) {
      this._favorites.add(e);
      _favorites.sort((TimelineEntry a, TimelineEntry b) {
        return a.start.compareTo(b.start);
      });
      _save();
    }
  }

  /// Remove the entry and save to disk.
  removeFavorite(TimelineEntry e) {
    if (_favorites.contains(e)) {
      this._favorites.remove(e);
      _save();
    }
  }

  /// Persists the data to disk.
  _save() {
    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      List<String> favsList =
          _favorites.map((TimelineEntry en) => en.label).toList();
      prefs.setStringList(FavoritesBloc.FAVORITES_KEY, favsList);
    });
  }
}
