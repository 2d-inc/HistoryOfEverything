import "package:shared_preferences/shared_preferences.dart";

import "package:timeline/timeline/timeline_entry.dart";

class FavoritesBloc
{
    static const String FAVORITES_KEY = "Favorites";
    final List<TimelineEntry> _favorites = [];

    init(List<TimelineEntry> entries) async
    {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> favs = prefs.getStringList(FavoritesBloc.FAVORITES_KEY);
        Map<String, TimelineEntry> entriesMap = new Map();
        for(TimelineEntry e in entries)
        {
            entriesMap.putIfAbsent(e.label, () => e);
        }
        if(favs != null)
        {
            for(String f in favs)
            {
                _favorites.add(entriesMap[f]);
            }
        }
		_favorites.sort((TimelineEntry a, TimelineEntry b)
		{
			return a.start.compareTo(b.start);
		});
    }

    List<TimelineEntry> get favorites
    {
        return _favorites;
    }

    addFavorite(TimelineEntry e)
    {
        if(!_favorites.contains(e))
        {
            this._favorites.add(e);
            _save();
        }
    }

    removeFavorite(TimelineEntry e)
    {
        if(_favorites.contains(e))
        {
            this._favorites.remove(e);
            _save();
        }
    }

    _save()
    {
        SharedPreferences.getInstance().then(
            (SharedPreferences prefs)
            {
                List<String> favsList = _favorites.map((TimelineEntry en) => en.label).toList();
                prefs.setStringList(FavoritesBloc.FAVORITES_KEY, favsList);
            }
        );
    }
}