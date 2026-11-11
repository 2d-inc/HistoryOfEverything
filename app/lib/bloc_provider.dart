import "package:flutter/widgets.dart";
import "package:timeline/blocs/favorites_bloc.dart";
import 'package:timeline/search_manager.dart';
import 'package:timeline/l10n/app_localizations.dart';
import 'package:timeline/timeline/timeline.dart';
import 'package:timeline/timeline/timeline_entry.dart';

/// This widget initializes shared data once and exposes an inherited scope
/// to the user's favorites through the [FavoritesBloc]
/// and the [Timeline] object.
class BlocProvider extends StatefulWidget {
  final FavoritesBloc favoritesBloc;
  final Timeline timeline;
  final Widget child;
  final AppLocalizations localizations;
  final TargetPlatform platform;

  /// This widget is initialized when the app boots up, and thus loads the resources.
  /// The timeline.json file contains all the entries' data.
  /// Once those entries have been loaded, load also all the favorites.
  /// Lastly use the entries' references to load a local dictionary for the [SearchManager].
  BlocProvider(
      {Key key,
      FavoritesBloc fb,
      Timeline t,
      @required Widget child,
      this.localizations = const AppLocalizations(),
      TargetPlatform platform = TargetPlatform.iOS})
      : timeline = t,
        favoritesBloc = fb,
        child = child,
        platform = platform,
        super(key: key);

  @override
  _BlocProviderState createState() => _BlocProviderState();

  static FavoritesBloc favorites(BuildContext context) =>
      (context.inheritFromWidgetOfExactType(_BlocScope) as _BlocScope)
          ?.favoritesBloc;

  static Timeline getTimeline(BuildContext context) =>
      (context.inheritFromWidgetOfExactType(_BlocScope) as _BlocScope)
          ?.timeline;
}

class _BlocProviderState extends State<BlocProvider> {
  Timeline timeline;
  FavoritesBloc favoritesBloc;

  @override
  void initState() {
    super.initState();
    timeline =
        widget.timeline ?? Timeline(widget.platform, widget.localizations);
    favoritesBloc = widget.favoritesBloc ?? FavoritesBloc();
    timeline
        .loadFromBundle("assets/timeline.json")
        .then((List<TimelineEntry> entries) async {
      if (!mounted) return;
      timeline.setViewport(
          start: entries.first.start * 2.0,
          end: entries.first.start,
          animate: true);

      /// Advance the timeline to its starting position.
      timeline.advance(0.0, false);

      /// All the entries are loaded, we can fill in the [favoritesBloc]...
      await favoritesBloc.init(entries);
      if (!mounted) return;

      /// ...and initialize the [SearchManager].
      SearchManager.init(entries);
    });
  }

  @override
  Widget build(BuildContext context) => _BlocScope(
      timeline: timeline, favoritesBloc: favoritesBloc, child: widget.child);

  @override
  void dispose() {
    timeline.isActive = false;
    super.dispose();
  }
}

class _BlocScope extends InheritedWidget {
  final Timeline timeline;
  final FavoritesBloc favoritesBloc;

  _BlocScope({this.timeline, this.favoritesBloc, Widget child})
      : super(child: child);

  @override
  bool updateShouldNotify(_BlocScope old) =>
      timeline != old.timeline || favoritesBloc != old.favoritesBloc;
}
