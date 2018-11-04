import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:timeline/article/article_widget.dart';
import 'package:timeline/main_menu/menu_data.dart';
import 'package:timeline/timeline/timeline.dart';
import 'package:timeline/timeline/timeline_entry.dart';
import 'package:timeline/timeline/timeline_render_widget.dart';

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
	Offset _lastFocalPoint;
	double _scaleStartYearStart = -100.0;
	double _scaleStartYearEnd = 100.0;
	TimelineEntry _touchedEntry;

    @override
    void initState() 
    {
        super.initState();
        widget.timeline.isActive = true;
    }

	void _scaleStart(ScaleStartDetails details, Timeline timeline)
	{
		_lastFocalPoint = details.focalPoint;
		_scaleStartYearStart = timeline.start;
		_scaleStartYearEnd = timeline.end;
		timeline.isInteracting = true;
		timeline.setViewport(velocity: 0.0, animate: true);
	}

	void _scaleUpdate(ScaleUpdateDetails details, Timeline timeline)
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

	void _scaleEnd(ScaleEndDetails details, Timeline timeline)
	{
		double scale = (timeline.end-timeline.start)/context.size.height;
		timeline.isInteracting = false;
		timeline.setViewport(velocity: details.velocity.pixelsPerSecond.dy * scale, animate: true);
	}
	
	onTouchBubble(Bubble bubble, BuildContext context)
	{
        if(bubble != null)
        {
            widget.timeline.isActive = false;
            Navigator.of(context).push(
                PageRouteBuilder(
                    opaque: true,
                    transitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (context, _, __) => ArticleWidget(article: bubble.entry),
                    transitionsBuilder: (_, Animation<double> animation, __, Widget child)
                    {
                        return new SlideTransition(
                            child: child,
                            position: new Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero
                            ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.fastOutSlowIn
                            ))
                        );
                    }
                )
            ).then((v) => widget.timeline.isActive = true);
            // result.then((bool done) => widget.timeline.isActive = done);
        }
	}

	onTouchEntry(TimelineEntry entry)
	{
		_touchedEntry = entry;
	}

	void _tapUp(TapUpDetails details, Timeline timeline)
	{
		if(_touchedEntry != null)
		{	
			TimelineEntry next = _touchedEntry.next;
			while(next != null && next.start == _touchedEntry.start)
			{
				next = next.next;
			}
			if(next != null)
			{
				timeline.setViewport(start:_touchedEntry.start, end:next.start, animate: true, pad: true);
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
					timeline.setViewport(start:prev.start, end:_touchedEntry.start, animate: true, pad: true);
				}
				else
				{
					print("Couldn't find a range.");
				}
			}
			
		}
	}

	@override
	Widget build(BuildContext context) 
	{
		EdgeInsets devicePadding = MediaQuery.of(context).padding;
		return Scaffold(
            body: GestureDetector(
                onScaleStart: (ScaleStartDetails d)=>_scaleStart(d, widget.timeline),
                onScaleUpdate: (ScaleUpdateDetails d)=>_scaleUpdate(d, widget.timeline),
                onScaleEnd: (ScaleEndDetails d)=>_scaleEnd(d, widget.timeline),
                onTapUp: (TapUpDetails d)=>_tapUp(d, widget.timeline),
                child: new Stack(
                    children:<Widget>
                    [
                        new TimelineRenderWidget(timeline: widget.timeline, topOverlap:56.0+devicePadding.top,focusItem:widget.focusItem,
                        touchBubble: (Bubble b) => onTouchBubble(b, context),
                        touchEntry:onTouchEntry),
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
                                        onPressed: (){
                                            // Go back to the menu.
                                            widget.timeline.isActive = false;
                                            Navigator.of(context).pop();
                                            return true;
                                        },
                                    )
                                )
                            ]
                        )
                    ]
                )
            ),
		);
	}
}
