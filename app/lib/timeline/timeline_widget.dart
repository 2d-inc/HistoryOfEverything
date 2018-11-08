import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:timeline/article/article_widget.dart';
import 'package:timeline/main_menu/menu_data.dart';
import 'package:timeline/timeline/timeline.dart';
import 'package:timeline/timeline/timeline_entry.dart';
import 'package:timeline/timeline/timeline_render_widget.dart';
import "package:timeline/colors.dart";

typedef ShowMenuCallback();
typedef SelectItemCallback(TimelineEntry item);

class TimelineWidget extends StatefulWidget 
{
	final MenuItemData focusItem;
    final Timeline timeline;
	TimelineWidget(this.focusItem, this.timeline, {Key key}) : super(key: key);

	@override
	_TimelineWidgetState createState() => new _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> 
{
	static const String DefaultEraName = "Birth of the Universe";

	Offset _lastFocalPoint;
	double _scaleStartYearStart = -100.0;
	double _scaleStartYearEnd = 100.0;
	static const double TopOverlap = 56.0;
	TapTarget _touchedBubble;
	TimelineEntry _touchedEntry;
	String _eraName;
	Timeline get timeline => widget.timeline;
	bool _didScale = false;
	Color _headerTextColor;
	Color _headerBackgroundColor;

	void _scaleStart(ScaleStartDetails details)
	{
		_didScale = false;
		_lastFocalPoint = details.focalPoint;
		_scaleStartYearStart = timeline.start;
		_scaleStartYearEnd = timeline.end;
		timeline.isInteracting = true;
		timeline.setViewport(velocity: 0.0, animate: true);
	}

	void _scaleUpdate(ScaleUpdateDetails details)
	{
		double changeScale = details.scale;
		double scale = (_scaleStartYearEnd-_scaleStartYearStart)/context.size.height;
		
		double focus = _scaleStartYearStart + details.focalPoint.dy * scale;
		double focalDiff = (_scaleStartYearStart + _lastFocalPoint.dy * scale) - focus;
		if(changeScale != 1.0)
		{
			_didScale = true;
		}
		timeline.setViewport(
			start: focus + (_scaleStartYearStart-focus)/changeScale + focalDiff,
			end: focus + (_scaleStartYearEnd-focus)/changeScale + focalDiff,
			height: context.size.height,
			animate: true);
	}

    initState()
    {
        super.initState();
		if(timeline != null)
		{
            widget.timeline.isActive = true;
			_eraName = timeline.currentEra != null ? timeline.currentEra.label : DefaultEraName;
			timeline.onHeaderColorsChanged = (Color background, Color text)
			{
				setState(() 
				{
					_headerTextColor = text;
					_headerBackgroundColor = background;
				});
			};
			timeline.onEraChanged = (TimelineEntry entry)
			{
				setState(() 
				{
					_eraName = entry != null ? entry.label : DefaultEraName;
				});
			};

			_headerTextColor = timeline.headerTextColor;
			_headerBackgroundColor = timeline.headerBackgroundColor;
		}
	}

	void didUpdateWidget(covariant TimelineWidget oldWidget)
	{
		super.didUpdateWidget(oldWidget);

		if(timeline != oldWidget.timeline && timeline != null)
		{
			setState(() 
			{
				_headerTextColor = timeline.headerTextColor;
				_headerBackgroundColor = timeline.headerBackgroundColor;
			});
			
			timeline.onHeaderColorsChanged = (Color background, Color text)
			{
				setState(() 
				{
					_headerTextColor = text;
					_headerBackgroundColor = background;
				});
			};
			timeline.onEraChanged = (TimelineEntry entry)
			{
				setState(() 
				{
					_eraName = entry != null ? entry.label : DefaultEraName;
				});
			};
			setState(() 
			{
				_eraName = timeline.currentEra != null ? timeline.currentEra : DefaultEraName;
			});
		}
	}

	void _scaleEnd(ScaleEndDetails details)
	{
		//double scale = (timeline.end-timeline.start)/context.size.height;
		timeline.isInteracting = false;
		if(_didScale)
		{
			timeline.clampScroll();
		}
		timeline.setViewport(velocity: details.velocity.pixelsPerSecond.dy, animate: true);
	}
	
	onTouchBubble(TapTarget bubble)
	{
        _touchedBubble = bubble;
	}

	onTouchEntry(TimelineEntry entry)
	{
		_touchedEntry = entry;
	}

	void _tapUp(TapUpDetails details)
	{
		EdgeInsets devicePadding = MediaQuery.of(context).padding;
        if(_touchedBubble != null)
        {
            widget.timeline.isActive = false;
            
            Navigator.of(context).push(
                CupertinoPageRoute(
                    builder: (BuildContext context) => ArticleWidget(article: _touchedBubble.entry)
                )
            ).then((v) => widget.timeline.isActive = true);
        }
        else if(_touchedEntry != null)
		{	
			MenuItemData target = MenuItemData.fromEntry(_touchedEntry);
			
			double topPadding = timeline.screenPaddingInTime(TopOverlap+devicePadding.top+target.padTop, target.start, target.end);
			double bottomPadding = timeline.screenPaddingInTime(target.padBottom, target.start, target.end);

			timeline.setViewport(start:target.start-topPadding, end:target.end+bottomPadding, animate: true);
		}
	}

	void _tapDown(TapDownDetails details)
	{
		timeline.setViewport(velocity: 0.0, animate: true);
	}

	@override
	Widget build(BuildContext context) 
	{
		EdgeInsets devicePadding = MediaQuery.of(context).padding;
		if(timeline != null)
		{
			timeline.setPadding(devicePadding);
		}
		return Scaffold(
                backgroundColor: Colors.white,
                body: GestureDetector(
                onTapDown: _tapDown,
                onScaleStart: _scaleStart,
                onScaleUpdate: _scaleUpdate,
                onScaleEnd: _scaleEnd,
                onTapUp: _tapUp,
                child: Stack(
                    children:<Widget>
                    [
                        TimelineRenderWidget(timeline: timeline, topOverlap:TopOverlap+devicePadding.top, focusItem:widget.focusItem, touchBubble:onTouchBubble, touchEntry:onTouchEntry),
                        BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                    Container(
                                        height:devicePadding.top,
                                        color:_headerBackgroundColor != null ? _headerBackgroundColor : Color.fromRGBO(238, 240, 242, 0.81)
                                    ),
                                    Container(
                                        color:_headerBackgroundColor != null ? _headerBackgroundColor : Color.fromRGBO(238, 240, 242, 0.81), 
                                        height: 56.0,
                                        width: double.infinity,
                                        child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: <Widget>[
                                            IconButton(
                                                padding: EdgeInsets.only(left:20.0, right:20.0),
                                                color: _headerTextColor != null ? _headerTextColor : Colors.black.withOpacity(0.5),
                                                alignment: Alignment.centerLeft,
                                                icon: Icon(Icons.menu),
                                                onPressed: () {
                                                    widget.timeline.isActive = false;
                                                    Navigator.of(context).pop();
                                                    return true;
                                                },
                                            ),
                                            Text(_eraName,
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                    fontFamily: "RobotoMedium",
                                                    fontSize: 20.0,
                                                    color: _headerTextColor != null ? _headerTextColor : darkText.withOpacity(darkText.opacity * 0.75)
                                                ),
                                            )
                                        ])
                                    )
                                ]
                            )
                        )
                    ]
                )
            ),
		);
	}
}
