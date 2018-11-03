import "package:flutter/material.dart";

import "package:timeline/bloc_provider.dart";
import "package:timeline/blocs/favorites_bloc.dart";
import "package:timeline/main_menu/menu_data.dart";
import "package:timeline/article/article_widget.dart";
import "package:timeline/timeline/timeline_widget.dart";
import "package:timeline/timeline/timeline_entry.dart";
import "package:timeline/main_menu/main_menu.dart";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
            favoritesBloc: FavoritesBloc(),
            child:MaterialApp(
                title: 'History & Future of Everything',
                theme: new ThemeData(
                    primarySwatch: Colors.blue,
                ),
                home: MyHomePage(title: 'Home Page')
        )
    );
  }
}

class MyHomePage extends StatefulWidget  {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

	bool _isTimelineActive = false;
	MenuData _menu;
	MenuItemData _focusItem;
	MenuItemData _nextFocusItem;
	bool _isMenuVisible = true;
	bool _isArticleVisible = false;
	TimelineEntry _article = null;

	initState()
	{
		super.initState();
		MenuData menu = new MenuData();
		menu.loadFromBundle("assets/menu.json").then((bool success)
		{
			setState(()
			{
				if(success)
				{
					_menu = menu;
				}
			});
		});					
	}

	void _selectMenuItem(MenuItemData menuItem)
	{
		setState(() 
		{
			// Start showing the timeline as soon as we select a menu item.
			_isTimelineActive = true;

			// Mark the next focus item so the timeline will go to it.
			_nextFocusItem = menuItem;

			// Update visibility state for menu and article.
			_isMenuVisible = false;
			_isArticleVisible = false;
		});
	}

	void _onShowMenu()
    {
		setState(() 
		{
			_isMenuVisible = true;
			_isArticleVisible = false;
		});
    }

	void _onMainMenuVisibilityChanged(bool isVisible)
	{
		setState(() 
		{
			if(isVisible)
			{
				_isTimelineActive = false;
				_focusItem = null;
			}
			else
			{
				_isTimelineActive = true;
				_focusItem = _nextFocusItem;
				_nextFocusItem = null;
			}
		});
	}

	void _returnToTimeline()
	{
		setState(() 
		{
			_isMenuVisible = false;
			_isArticleVisible = false;
			_isTimelineActive = true;
		});
	}

	void _onArticleVisibilityChanged(bool isVisible)
	{
		if(isVisible)
		{
			setState(() 
			{
				_isTimelineActive = false;
			});
		}
	}

	void _selectTimelineEntry(TimelineEntry entry)
	{
		setState(() 
		{
			_article = entry;
			_isMenuVisible = false;
			_isArticleVisible = true;
		});
	}

    @override
    dispose()
    {
        super.dispose();
    }

	@override
	Widget build(BuildContext context) 
	{
		if(_menu == null)
		{
			// Still loading.
			return new Container();
		}
		return new Scaffold(
            appBar: null,
            body: new Stack(
                children: <Widget> [
                    Positioned.fill( child: TimelineWidget( showMenu: _onShowMenu, isActive:_isTimelineActive, focusItem:_focusItem, selectItem: _selectTimelineEntry )),
                    Positioned.fill( child: MainMenuWidget( show:_isMenuVisible, selectItem: _selectMenuItem, data:_menu, visibilityChanged:_onMainMenuVisibilityChanged) ),
                    Positioned.fill( child: ArticleWidget( show:_isArticleVisible, article:_article, goBack: _returnToTimeline, visibilityChanged: _onArticleVisibilityChanged) )
                ]
            )
		);
	}
}