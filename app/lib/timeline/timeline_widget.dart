import 'dart:math';
import 'package:flutter/material.dart';
import "package:flutter/scheduler.dart";
import "dart:ui" as ui;

import 'package:timeline/timeline/ticks.dart';

class TimelineWidget extends StatefulWidget 
{
	TimelineWidget({Key key}) : super(key: key);

	@override
	_TimelineWidgetState createState() => new _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> 
{
	double _yearStart = -4600000000.0;
	double _yearEnd = 2018.0;

	void _scaleStart(ScaleStartDetails details)
	{
		print("SCALE START ${details.focalPoint}");
		//_level.editor.onScaleStart(details);
	}

	void _scaleUpdate(ScaleUpdateDetails details)
	{
		print("SCALE UPDATE ${details.focalPoint} ${details.scale}");
		//_level.editor.onScaleUpdate(details);
	}

	void _scaleEnd(ScaleEndDetails details)
	{
		print("SCALE END");
		//_level.editor.onScaleEnd(details);
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
							child: new TimelineRenderWidget(yearStart: _yearStart, yearEnd: _yearEnd)
						) )
			]);
	}
}

class TimelineRenderWidget extends LeafRenderObjectWidget
{
	final double yearStart;
	final double yearEnd;
	TimelineRenderWidget({Key key, this.yearStart, this.yearEnd}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new TimelineRenderObject()
							..yearStart = yearStart
							..yearEnd = yearEnd;
	}

	@override
	void updateRenderObject(BuildContext context, covariant TimelineRenderObject renderObject)
	{
		renderObject
					..yearStart = yearStart
					..yearEnd = yearEnd;
	}
}

class TimelineRenderObject extends RenderBox
{
	double _yearStart;
	double _yearEnd;
	Ticks _ticks = new Ticks();

	double get yearStart => yearStart;
	set yearStart(double yearStart)
	{
		if(_yearStart == yearStart)
		{
			return;
		}
		_yearStart = yearStart;
		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
	}

	double get yearEnd => yearEnd;
	set yearEnd(double yearEnd)
	{
		if(_yearEnd == yearEnd)
		{
			return;
		}
		_yearEnd = yearEnd;
		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
	}

	void beginFrame(Duration timeStamp) 
	{
		markNeedsPaint();
		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
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

		double renderStart = _yearStart;
		double renderEnd = _yearEnd;
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
