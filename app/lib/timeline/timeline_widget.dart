import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:timeline/main_menu/menu_data.dart';
import 'package:timeline/timeline/timeline.dart';
import 'package:timeline/timeline/timeline_entry.dart';
import 'package:timeline/timeline/timeline_render_widget.dart';

typedef ShowMenuCallback();
typedef SelectItemCallback(TimelineEntry item);

class TimelineWidget extends StatefulWidget 
{
	final ShowMenuCallback showMenu;
	final bool isActive;
	final MenuItemData focusItem;
	final SelectItemCallback selectItem;
	final Timeline timeline;
	TimelineWidget({this.showMenu, this.isActive, this.focusItem, this.selectItem, this.timeline, Key key}) : super(key: key);

	@override
	_TimelineWidgetState createState() => new _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> 
{
	Offset _lastFocalPoint;
	double _scaleStartYearStart = -100.0;
	double _scaleStartYearEnd = 100.0;
	static const double TopOverlap = 56.0;
	Bubble _touchedBubble;
	TimelineEntry _touchedEntry;

	Timeline get timeline => widget.timeline;
	void _scaleStart(ScaleStartDetails details)
	{
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
		
		timeline.setViewport(
			start: focus + (_scaleStartYearStart-focus)/changeScale + focalDiff,
			end: focus + (_scaleStartYearEnd-focus)/changeScale + focalDiff,
			height: context.size.height,
			animate: true);
	}

	void _scaleEnd(ScaleEndDetails details)
	{
		double scale = (timeline.end-timeline.start)/context.size.height;
		timeline.isInteracting = false;
		timeline.setViewport(velocity: details.velocity.pixelsPerSecond.dy * scale, animate: true);
	}
	
	onTouchBubble(Bubble bubble)
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
			widget.selectItem(_touchedBubble.entry);
		}
		else if(_touchedEntry != null)
		{	
			MenuItemData target = MenuItemData.fromEntry(_touchedEntry);
			
			double topPadding = timeline.screenPaddingInTime(TopOverlap+devicePadding.top+target.padTop, target.start, target.end);
			double bottomPadding = timeline.screenPaddingInTime(target.padBottom, target.start, target.end);

			timeline.setViewport(start:target.start-topPadding, end:target.end+bottomPadding, animate: true);
		}
	}


	@override
	Widget build(BuildContext context) 
	{
		EdgeInsets devicePadding = MediaQuery.of(context).padding;
		return new GestureDetector(
			onScaleStart: _scaleStart,
			onScaleUpdate: _scaleUpdate,
			onScaleEnd: _scaleEnd,
			onTapUp: _tapUp,
			child: new Stack(
				children:<Widget>
				[
					new TimelineRenderWidget(timeline: timeline, topOverlap:TopOverlap+devicePadding.top, isActive:widget.isActive, focusItem:widget.focusItem, touchBubble:onTouchBubble, touchEntry:onTouchEntry),
					new Column(
						children: <Widget>[
							Container(
								height:devicePadding.top,
								color:Color.fromRGBO(238, 240, 242, 0.81)
							),
							Container(
								color:Color.fromRGBO(238, 240, 242, 0.81), 
								height: 56.0,
								width: double.infinity,
								child: new IconButton(
									alignment: Alignment.centerLeft,
									icon: new Icon(Icons.menu),
									onPressed: () { this.widget.showMenu(); },
								)
							)
						]
					)
				]
			)
		);
	}
}
