import 'package:timeline/article/article_widget.dart';
import 'package:timeline/main_menu/menu_data.dart';
import 'package:timeline/search_manager.dart';
import 'package:timeline/timeline/timeline.dart';

import 'timeline/timeline_widget.dart';
import 'main_menu/main_menu.dart';
import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget  {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

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
        SearchManager();
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
			_nextFocusItem = menuItem;
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

/*

    return new Scaffold(
		drawer: SizedBox.expand(
			child: new Drawer(
				child: MainMenuWidget(selectItem: _onShowMenu),
      		),
		),
      	appBar: new AppBar(
        	title: new Text("Timeline"),
      	),
      	body: new Stack(
		  children: <Widget> [
			  Positioned.fill( child: TimelineWidget() ),
			  //Positioned.fill( left: _menuOffset, right: -_menuOffset, child: MainMenuWidget(selectItem: _onShowMenu) )
		  ]
		)
    );*/