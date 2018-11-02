import "package:flutter/widgets.dart";
import "package:timeline/blocs/favorites_bloc.dart";

class BlocProvider extends InheritedWidget
{
    final FavoritesBloc favoritesBloc;

    BlocProvider({Key key, FavoritesBloc favoritesBloc, @required Widget child}) : 
        favoritesBloc = favoritesBloc ?? new FavoritesBloc(),
        super(key: key, child: child);

    @override
    updateShouldNotify(InheritedWidget oldWidget) => true;

    static FavoritesBloc of(BuildContext context) 
    {
        BlocProvider bp = (context.inheritFromWidgetOfExactType(BlocProvider) as BlocProvider);
        FavoritesBloc bloc = bp?.favoritesBloc;
        return bloc;
    }
}