import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:share/share.dart";

import "menu_data.dart";
import "search_widget.dart";
import "main_menu_section.dart";
import "search_result_widget.dart";
import "../search_manager.dart";
import "../colors.dart";
import "../timeline/timeline_entry.dart";

typedef VisibilityChanged(bool isVisible);

class MainMenuWidget extends StatefulWidget  
{
	final SelectItemCallback selectItem;
	final MenuData data;
	final bool show;
	final VisibilityChanged visibilityChanged;
	MainMenuWidget({this.selectItem, this.data, this.show, this.visibilityChanged, Key key}) : super(key: key);

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

    ScrollController _scrollController;
    bool _isSearching = false;
    List<TimelineEntry> _searchResults = [];
    
    // This is passed to the SearchWidget so we can handle text edits and display the search results on the main menu.
    final TextEditingController _searchTextController = TextEditingController();
    final FocusNode _searchFocusNode = FocusNode();
    Timer _searchTimer;

	initState()
	{
		super.initState();

        _scrollController = new ScrollController();
        _searchTextController.addListener(() {
            String txt = _searchTextController.text.trim();
            if(_searchTimer != null && _searchTimer.isActive)
            {
                // Remove old timer.
                _searchTimer.cancel();
            }
            // Perform search.
            _searchTimer = new Timer(const Duration(milliseconds:350), (){
                Set<TimelineEntry> res = SearchManager.init().performSearch(txt);
                setState(() {
                    _searchResults = res.toList();   
                });
            });
        });

        _searchFocusNode.addListener(()
        {
            setState(() {
                _isSearching = _searchFocusNode.hasFocus;
                if(!_isSearching) _searchResults.clear();
            } );
        });

		_controller = AnimationController(
			vsync: this,
			duration: const Duration(milliseconds: 200),
		);
		_menuOffset = _controller.drive(_slideTween);		
		if(widget.show)
		{
			_controller.reverse();
		}
		else
		{
			_controller.forward();
		}									
	}

	void didUpdateWidget(covariant MainMenuWidget oldWidget) 
	{ 
		super.didUpdateWidget(oldWidget);
		if(oldWidget.show != widget.show)
		{
			if(widget.show)
			{
				_controller.reverse().whenComplete(()
				{
					setState(() 
					{
						widget.visibilityChanged(true);
					});
				});
			}
			else
			{
				_controller.forward().whenComplete(()
				{
					setState(() 
					{
						widget.visibilityChanged(false);
					});
				});
			}
		}
	}

    @override
    Widget build(BuildContext context) 
    {
        return SlideTransition(
			position: _menuOffset, 
			child: new Container(
				color: background,
				child: Container(
					padding: EdgeInsets.only(left: 20.0),
                    child: NestedScrollView(
                        controller: _scrollController,
                        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled)
                        => <Widget>[
                            SliverList(
                                delegate: SliverChildListDelegate(
                                    _isSearching ? [] :
                                    [
                                        Padding(
                                            padding: EdgeInsets.only(top: 36.0),
                                            child: Row(
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
                                            )
                                        ),
                                        Container(
                                            margin: EdgeInsets.only(top: 14.0),
                                            child: Text(
                                                "The History & Future\nof Everything",
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                        color: darkText.withOpacity(darkText.opacity*0.75),
                                                        fontSize: 34.0,
                                                        fontFamily: "RobotoMedium"
                                                    )
                                                )
                                        )
                                    ]
                                ),
                            ),
                            SliverAppBar(
                                backgroundColor: background,
                                pinned: true,
                                title: Padding(
                                    padding: EdgeInsets.only(right: 20.0),
                                    child: SearchWidget(_searchFocusNode, _searchTextController)
                                ),
                                titleSpacing: 0.0
                            ),
                        ],
                        body: SingleChildScrollView(
                            child: 
                            _isSearching ? Column(
                                children: [
                                    ]..addAll(
                                    _searchResults.map((TimelineEntry sr)
                                        {
                                            return SearchResultWidget(sr, "assets/dino.jpg", () {
                                                TimelineEntry te = sr;
                                                SystemChannels.textInput.invokeMethod('TextInput.hide');
                                                double start = te.start;
                                                double end = (te.type == TimelineEntryType.Era) ? te.start : te.end;
                                                if(start == end)
                                                {
                                                    // Use 2.5% of the current timeline entry date to estimate start/end.
                                                    double distance = start * 0.025;
                                                    print("CHANGING START: $start, $end, $distance");
                                                    start += distance;
                                                    end -= distance;
                                                    print("Changed to: $start, $end, $distance");
                                                }

                                                widget.selectItem(MenuItemData.fromData(sr.label, start, end));
                                            });
                                        }
                                    )
                                )
                            ) :
                                Column(
                                children: 
                                    []..addAll(
                                    widget.data.sections.map((MenuSectionData section)
                                        => Container(
                                            margin: EdgeInsets.only(top:20.0, right:20.0),
                                            child: MenuSection(
                                                section.label, 
                                                section.backgroundColor, 
                                                section.textColor, 
                                                section.items,
                                                widget.selectItem
                                                )
                                            )
                                        )
                                    )..add(
                                        Container(
                                            margin: EdgeInsets.symmetric(vertical:40.0),
                                            height: 1.0,
                                            color: const Color.fromRGBO(151, 151, 151, 0.29),
                                        )
                                    )
                                    ..add(
                                        FlatButton(
                                            onPressed: () => print("FAVS"),
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
                                              onPressed: () => print("ABOUT?"),
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
                                    )
                                )
                            )
                    )
				)
			)
		);
    }
}