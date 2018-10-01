import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import "package:flutter/scheduler.dart";
import "dart:ui" as ui;

import 'package:timeline/timeline/ticks.dart';
import 'package:timeline/timeline/timeline.dart';

class TimelineWidget extends StatefulWidget 
{
	TimelineWidget({Key key}) : super(key: key);

	@override
	_TimelineWidgetState createState() => new _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> 
{
	Timeline _timeline = new Timeline();

	Offset _lastFocalPoint;
	double _scaleStartYearStart = -100.0;
	double _scaleStartYearEnd = 100.0;

	void _scaleStart(ScaleStartDetails details)
	{
		_lastFocalPoint = details.focalPoint;
		_scaleStartYearStart = _timeline.start;
		_scaleStartYearEnd = _timeline.end;
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
		_timeline.setViewport(velocity: details.velocity.pixelsPerSecond.dy * scale, animate: true);
	}


	@override
	Widget build(BuildContext context) 
	{
		return new Stack(
			children:<Widget>
			[
				new Positioned.fill(
						child: new GestureDetector(
							onScaleStart: _scaleStart,
							onScaleUpdate: _scaleUpdate,
							onScaleEnd: _scaleEnd,
							//onTapUp: _tapUp,
							child: new TimelineRenderWidget(timeline: _timeline)
						)
						// 
				)
			]);
	}
}

class TimelineRenderWidget extends LeafRenderObjectWidget
{
	final Timeline timeline;
	TimelineRenderWidget({Key key, this.timeline}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new TimelineRenderObject()
							..timeline = timeline;
	}

	@override
	void updateRenderObject(BuildContext context, covariant TimelineRenderObject renderObject)
	{
		renderObject
					..timeline = timeline;
	}
}

class TimelineRenderObject extends RenderBox
{
	Ticks _ticks = new Ticks();
	Timeline _timeline;

	Timeline get timeline => _timeline;
	set timeline(Timeline value)
	{
		if(_timeline == value)
		{
			return;
		}
		_timeline = value;
		_timeline.onNeedPaint = ()
		{
			markNeedsPaint();
		};
	}

	@override
	bool get sizedByParent => true;
	
	@override
	bool hitTestSelf(Offset screenOffset) => true;

	@override
	void performResize() 
	{
		size = constraints.biggest;
	}

	@override
	void paint(PaintingContext context, Offset offset)
	{
		//print("Paint Nima");
		final Canvas canvas = context.canvas;
		if(_timeline == null)
		{
			return;
		}

		double renderStart = _timeline.renderStart;
		double renderEnd = _timeline.renderEnd;
		double scale = size.height/(renderEnd-renderStart);

		//canvas.drawRect(new Offset(0.0, 0.0) & new Size(100.0, 100.0), new Paint()..color = Colors.red);
		_ticks.paint(context, offset, -renderStart*scale, scale, size.height);
		
		// double width = _aabb[2] - _aabb[0];
		// double height = _aabb[3] - _aabb[1];

		// double scale = max(size.width/width, size.height/height);
		// canvas.translate(offset.dx + size.width/2.0, offset.dy + size.height/2.0);
		// canvas.scale(scale, -scale);
		// canvas.translate(-_aabb[0] - width/2.0, -_aabb[1] - height/2.0);
		
		// //canvas.translate(280.0, -1050.0);
		// _actorInstance.draw(canvas);
		//print("SIZE IS ${size.width}, ${size.height}");
		// canvas.scale(1.0/ui.window.devicePixelRatio, 1.0/ui.window.devicePixelRatio);
		// _level.render(canvas);
	}

	@override
	markNeedsPaint()
	{
		super.markNeedsPaint();
	}
}
