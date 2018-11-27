import "package:flutter/widgets.dart";
import "package:timeline/blocs/favorites_bloc.dart";
import 'package:timeline/search_manager.dart';
import 'package:timeline/timeline/timeline.dart';
import 'package:timeline/timeline/timeline_entry.dart';

class BlocProvider extends InheritedWidget {
  final FavoritesBloc favoritesBloc;
  final Timeline timeline;

  BlocProvider(
      {Key key,
      FavoritesBloc fb,
      Timeline t,
      @required Widget child,
      TargetPlatform platform = TargetPlatform.iOS})
      : timeline = t ?? Timeline(platform),
        favoritesBloc = fb ?? FavoritesBloc(),
        super(key: key, child: child) {
    timeline
        .loadFromBundle("assets/timeline.json")
        .then((List<TimelineEntry> entries) {
      timeline.setViewport(
          start: entries.first.start * 2.0,
          end: entries.first.start,
          animate: true);
      timeline.advance(0.0, false);

      // All the entries are loaded, we can fill in the favoritesBloc
      favoritesBloc.init(entries);
      SearchManager.init(entries);
    });
  }

  @override
  updateShouldNotify(InheritedWidget oldWidget) => true;

  static FavoritesBloc favorites(BuildContext context) {
    BlocProvider bp =
        (context.inheritFromWidgetOfExactType(BlocProvider) as BlocProvider);
    FavoritesBloc bloc = bp?.favoritesBloc;
    return bloc;
  }

  static Timeline getTimeline(BuildContext context) {
    BlocProvider bp =
        (context.inheritFromWidgetOfExactType(BlocProvider) as BlocProvider);
    Timeline bloc = bp?.timeline;
    return bloc;
  }
}
