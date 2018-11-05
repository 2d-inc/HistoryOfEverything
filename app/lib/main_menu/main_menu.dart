import "dart:async";

import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:share/share.dart";
import 'package:timeline/bloc_provider.dart';
import 'package:timeline/main_menu/collapsible.dart';

import "package:timeline/main_menu/menu_data.dart";
import "package:timeline/main_menu/search_widget.dart";
import "package:timeline/main_menu/main_menu_section.dart";
import "package:timeline/main_menu/about_page.dart";
import "package:timeline/main_menu/favorites_page.dart";
import 'package:timeline/main_menu/thumbnail_detail_widget.dart';
import "package:timeline/search_manager.dart";
import "package:timeline/colors.dart";
import "package:timeline/timeline/timeline_entry.dart";
import 'package:timeline/timeline/timeline_widget.dart';

class MainMenuWidget extends StatefulWidget  
{
	MainMenuWidget({Key key}) : super(key: key);

	@override
	 _MainMenuWidgetState createState() => new _MainMenuWidgetState();
}

class _MainMenuWidgetState extends State<MainMenuWidget> with SingleTickerProviderStateMixin
{
	AnimationController _controller;
	static final Animatable<Offset> _slideTween = Tween<Offset>(
		begin: const Offset(0.0, 0.0),
		end: const Offset(-1.0, 0.0),
	).chain(CurveTween(
		curve: Curves.fastOutSlowIn,
	));
	Animation<Offset> _menuOffset;
    bool _isSearching = false;
    bool _isSectionActive = true;
    List<TimelineEntry> _searchResults = new List<TimelineEntry>();
    final MenuData _menu = new MenuData();
    
    // This is passed to the SearchWidget so we can handle text edits and display the search results on the main menu.
    final TextEditingController _searchTextController = TextEditingController();
    final FocusNode _searchFocusNode = FocusNode();
    Timer _searchTimer;

	cancelSearch()
	{
 		if(_searchTimer != null && _searchTimer.isActive)
		{
			// Remove old timer.
			_searchTimer.cancel();
			_searchTimer = null;
		}
	}

    navigateToTimeline(MenuItemData item)
    {
        _pauseSection();                                                                
        Navigator.of(context).push(
            CupertinoPageRoute(
                builder: (BuildContext context) => new TimelineWidget(item, BlocProvider.getTimeline(context)),
            )
        ).then(_restoreSection);
    }

    _restoreSection(v) => setState(() => _isSectionActive = true);
    _pauseSection() => setState(() => _isSectionActive = false);

	updateSearch()
	{
		cancelSearch();
		if(!_isSearching)
		{
			setState(() 
			{
				_searchResults = new List<TimelineEntry>();
			});
			return;
		}
		// Perform search.
		String txt = _searchTextController.text.trim();
		_searchTimer = new Timer(Duration(milliseconds: txt.isEmpty ? 0 : 350), ()
		{
			Set<TimelineEntry> res = SearchManager.init().performSearch(txt);
			setState(() 
			{
				_searchResults = res.toList();
			});
		});
	}

	initState()
	{
		super.initState();

        _menu.loadFromBundle("assets/menu.json").then((bool success){
            if(success) setState(() {}); // Load the menu.
        });

        _searchTextController.addListener(() {
			updateSearch();
        });

        _searchFocusNode.addListener(()
        {
            setState(() {
                _isSearching = _searchFocusNode.hasFocus;
				updateSearch();
            } );
        });

		_controller = AnimationController(
			vsync: this,
			duration: const Duration(milliseconds: 200),
		);
		_menuOffset = _controller.drive(_slideTween);						
	}

    @override
    Widget build(BuildContext context) 
    {
		EdgeInsets devicePadding = MediaQuery.of(context).padding;

        List<Widget> tail = [];
		if(_isSearching)
        {
            for(int i = 0; i < _searchResults.length; i++)
            {
                tail.add(ThumbnailDetailWidget(_searchResults[i], hasDivider: i != 0));
            }
        }
        else
        {
            tail
                ..addAll(_menu.sections.map<Widget>((MenuSectionData section)
				  				=> Container(
				  					margin: EdgeInsets.only(top:20.0),
				  					child: MenuSection(
				  						section.label, 
				  						section.backgroundColor, 
				  						section.textColor, 
				  						section.items,
                                        navigateToTimeline,
                                        _isSectionActive,
										assetId: section.assetId,
				  						)
				  					)
				  				).toList(growable:false))
                ..add(
                        Container(
                            margin: EdgeInsets.only(top:40.0, bottom:22),
                            height: 1.0,
                            color: const Color.fromRGBO(151, 151, 151, 0.29),
                        )
                    )
                ..add(
                    FlatButton(
                        onPressed: () {
                            _pauseSection();
                            Navigator.of(context).push(
                                CupertinoPageRoute(
                                    builder: (BuildContext context) => new FavoritesPage()
                                )
                            ).then(_restoreSection);
                        },
                        color: Colors.transparent,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: 
                            [
                                Container(
                                    margin: EdgeInsets.only(right:15.5),
                                    child: Image.asset(
                                            "assets/heart_icon.png",
                                            height:20.0,
                                            width: 20.0,
                                            color: Colors.black
                                        ),
                                    ),
                                    Text(
                                        "Your Favorites",
                                        style: TextStyle(
                                            fontSize: 20.0,
                                            fontFamily: "RobotoMedium",
                                            color: darkText
                                        ),
                                    )
                            ]
                        )
                    )
                )
                ..add(
                    FlatButton(
                        onPressed: () => Share.share("Build your own animations at www.2dimensions.com"),
                        color: Colors.transparent,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: 
                            [
                                Container(
                                    margin: EdgeInsets.only(right:15.5),
                                    child: Image.asset(
                                            "assets/share_icon.png",
                                            height:20.0,
                                            width: 20.0,
                                            color: Colors.black
                                        ),
                                    ),
                                    Text(
                                        "Share",
                                        style: TextStyle(
                                            fontSize: 20.0,
                                            fontFamily: "RobotoMedium",
                                            color: darkText
                                        ),
                                    )
                            ]
                        )
                    )
                )
                ..add(
                    Padding(
                        padding: const EdgeInsets.only(bottom: 30.0),
                        child: FlatButton(
                            onPressed: () {
                                _pauseSection();
                                Navigator.of(context).push(
                                    CupertinoPageRoute(
                                        builder: (BuildContext context) => new AboutPage()
                                    )
                                ).then(_restoreSection);
                            },
                            color: Colors.transparent,
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: 
                                [
                                    Container(
                                        margin: EdgeInsets.only(right:15.5),
                                        child: Image.asset(
                                                "assets/info_icon.png",
                                                height:20.0,
                                                width: 20.0,
                                                color: Colors.black
                                            ),
                                        ),
                                        Text(
                                            "About",
                                            style: TextStyle(
                                                fontSize: 20.0,
                                                fontFamily: "RobotoMedium",
                                                color: darkText
                                            ),
                                        )
                                ]
                            )
                        ),
                    )
                );
        }
        return Container(
				color: background,
				child: Padding(
				  padding: EdgeInsets.only(top:devicePadding.top),
				  child: SingleChildScrollView(
					padding: EdgeInsets.only(top:20.0, left: 20, right:20, bottom: 20),
				  	child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
				  		children: <Widget>[
							  new Collapsible(
								isCollapsed: _isSearching,
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children:<Widget>[
										Padding(
											padding: const EdgeInsets.only(bottom:18.0),
											child: Row(
												crossAxisAlignment: CrossAxisAlignment.center,
												children: <Widget>[
													Image.asset("assets/flutter_logo.png",
														color: Colors.black.withOpacity(0.62),
														height: 22.0,
														width: 22.0
													),
													Container(
														margin: EdgeInsets.only(left: 10.0),
														child: Text(
															"Flutter Presents",
															style: TextStyle(
																color: darkText.withOpacity(darkText.opacity*0.75),
																fontSize: 16.0,
																fontFamily: "Roboto"
																)
														)
													)
												],
											),
										),
										Text(
											"The History of Everything",
											textAlign: TextAlign.left,
											style: TextStyle(
													color: darkText.withOpacity(darkText.opacity*0.75),
													fontSize: 34.0,
													fontFamily: "RobotoMedium"
												)
										)
									]
								)
							),
							Padding(
								padding: EdgeInsets.only(top:22.0),
								child: SearchWidget(_searchFocusNode, _searchTextController)
							)
				  		] 
                        + tail
				  		)
				  	),
				)
		);
    }
}