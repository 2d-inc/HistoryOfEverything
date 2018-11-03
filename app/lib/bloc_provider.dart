import "package:flutter/widgets.dart";
import "package:timeline/blocs/favorites_bloc.dart";
import 'package:timeline/timeline/timeline.dart';

class BlocProvider extends InheritedWidget
{
    final FavoritesBloc favoritesBloc;
    final Timeline timeline;

    BlocProvider({Key key, FavoritesBloc fb, Timeline t, @required Widget child}) : 
        favoritesBloc = fb ?? new FavoritesBloc(),
        timeline = t ?? new Timeline(),
        super(key: key, child: child);

    @override
    updateShouldNotify(InheritedWidget oldWidget) => true;

    static FavoritesBloc favorites(BuildContext context) 
    {
        BlocProvider bp = (context.inheritFromWidgetOfExactType(BlocProvider) as BlocProvider);
        FavoritesBloc bloc = bp?.favoritesBloc;
        return bloc;
    }

    static Timeline getTimeline(BuildContext context) 
    {
        BlocProvider bp = (context.inheritFromWidgetOfExactType(BlocProvider) as BlocProvider);
        Timeline bloc = bp?.timeline;
        return bloc;
    }
}