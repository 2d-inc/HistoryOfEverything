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
	TimelineWidget({this.showMenu, this.isActive, this.focusItem, this.selectItem, Key key}) : super(key: key);

	@override
	_TimelineWidgetState createState() => new _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> 
{
	Timeline _timeline = new Timeline();

	Offset _lastFocalPoint;
	double _scaleStartYearStart = -100.0;
	double _scaleStartYearEnd = 100.0;
	Bubble _touchedBubble;
	TimelineEntry _touchedEntry;

	void _scaleStart(ScaleStartDetails details)
	{
		_lastFocalPoint = details.focalPoint;
		_scaleStartYearStart = _timeline.start;
		_scaleStartYearEnd = _timeline.end;
		_timeline.isInteracting = true;
		_timeline.setViewport(velocity: 0.0, animate: true);
	}

	void _scaleUpdate(ScaleUpdateDetails details)
	{
		double changeScale = details.scale;
		double scale = (_scaleStartYearEnd-_scaleStartYearStart)/context.size.height;
		
		double focus = _scaleStartYearStart + details.focalPoint.dy * scale;
		double focalDiff = (_scaleStartYearStart + _lastFocalPoint.dy * scale) - focus;
		
		_timeline.setViewport(
			start: focus + (_scaleStartYearStart-focus)/changeScale + focalDiff,
			end: focus + (_scaleStartYearEnd-focus)/changeScale + focalDiff,
			height: context.size.height,
			animate: true);
	}

	void _scaleEnd(ScaleEndDetails details)
	{
		double scale = (_timeline.end-_timeline.start)/context.size.height;
		_timeline.isInteracting = false;
		_timeline.setViewport(velocity: details.velocity.pixelsPerSecond.dy * scale, animate: true);
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
		if(_touchedBubble != null)
		{
			widget.selectItem(_touchedBubble.entry);
		}
		else if(_touchedEntry != null)
		{	
			TimelineEntry next = _touchedEntry.next;
			while(next != null && next.start == _touchedEntry.start)
			{
				next = next.next;
			}
			if(next != null)
			{
				print("SETTING RANGE TO START ${_touchedEntry.start}, ${next.start}");
				_timeline.setViewport(start:_touchedEntry.start, end:next.start, animate: true, pad: true);
			}
			else
			{
				TimelineEntry prev = _touchedEntry.previous;
				while(prev != null && prev.start == _touchedEntry.start)
				{
					prev = prev.previous;
				}
				if(prev != null)
				{
					print("SETTING RANGE TO PREV ${prev.start}, ${_touchedEntry.start}");
					_timeline.setViewport(start:prev.start, end:_touchedEntry.start, animate: true, pad: true);
				}
				else
				{
					print("Couldn't find a range.");
				}
			}
			
		}
		//double scale = (_scaleStartYearEnd-_scaleStartYearStart)/context.size.height;
		//_timeline.onTap(details.globalPosition);
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
					new TimelineRenderWidget(timeline: _timeline, topOverlap:56.0+devicePadding.top, isActive:widget.isActive, focusItem:widget.focusItem, touchBubble:onTouchBubble, touchEntry:onTouchEntry),
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
