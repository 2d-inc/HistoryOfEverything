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

class TouchData
{
	int pointer;
	int index;
	double touchY;
	double moveY;

	double yearStart;
	double yearEnd;
}

class _TimelineWidgetState extends State<TimelineWidget> 
{
	Timeline _timeline = new Timeline();
	double _yearStart = -100.0;
	double _yearEnd = 100.0;
	double _velocity = 0.0;

	Offset _lastFocalPoint;
	double _scaleStartYearStart = -100.0;
	double _scaleStartYearEnd = 100.0;

	void _scaleStart(ScaleStartDetails details)
	{
		//print("SCALE START ${details.focalPoint}");
		_lastFocalPoint = details.focalPoint;

		_scaleStartYearStart = _timeline.start;
		_scaleStartYearEnd = _timeline.end;
		_timeline.setViewport(velocity: 0.0, animate: true);
		//_level.editor.onScaleStart(details);
	}

	void _scaleUpdate(ScaleUpdateDetails details)
	{
		
		//print("SCALE UPDATE ${details.focalPoint} ${details.scale}");

		//Offset focalDiff = (_lastFocalPoint-details.focalPoint);//*window.devicePixelRatio;
		
		//_lastFocalPoint = details.focalPoint;

		// double renderScale = context.size.height/(_yearStart-_yearEnd);

		// double focus = context.size.height / 2.0;
		// double scale = 1.5;

		double changeScale = details.scale;
		double scale = (_scaleStartYearEnd-_scaleStartYearStart)/context.size.height;
		
		double focus = _scaleStartYearStart + details.focalPoint.dy * scale;
		double focalDiff = (_scaleStartYearStart + _lastFocalPoint.dy * scale) - focus;
		
		_timeline.setViewport(
			start: focus + (_scaleStartYearStart-focus)/changeScale + focalDiff,
			end: focus + (_scaleStartYearEnd-focus)/changeScale + focalDiff,
			height: context.size.height,
			animate: true);
// 		setState(() 
// 		{		

// // 			SCALE UPDATE -100.0 260.4506887274359 -2.6045068872743586 1.5
// // I/flutter (12224): SCALE 2 260.4506887274359

// 			// print("SCALE UPDATE ${details.focalPoint} ${details.scale} $_yearStart $focus $renderScale $scale");
// 			// _yearStart = focus + (_scaleStartYearStart - focus / renderScale)*scale;
// 			// print("SCALE 2 $_yearStart");
// 			// print("----");
// 			_yearStart = focus + (_scaleStartYearStart-focus)/changeScale + focalDiff;// _scaleStartYearStart - (scaleFrom*rangeChange);
// 			_yearEnd = focus + (_scaleStartYearEnd-focus)/changeScale + focalDiff;
// 			//_yearStart = focus + (focus-_scaleStartYearStart)*changeScale;
// 			//_yearEnd = _scaleStartYearEnd + ((1.0-scaleFrom)*rangeChange);

			

// 		// this._Start = start - (scaleFrom*rangeChange);
// 		// this._End = end + ((1.0-scaleFrom)*rangeChange);

// 			// _yearEnd = details.focalPoint.dy + (_scaleStartYearEnd - details.focalPoint.dy / scale)*details.scale;
// 			 //_yearStart -= focalDiff.dy / scale;
// 			 //_yearEnd -= focalDiff.dy / scale;
// 		});
		//_level.editor.onScaleUpdate(details);
	}

	TouchData _touchA, _touchB;

	void _scaleEnd(ScaleEndDetails details)
	{
		double scale = (_timeline.end-_timeline.start)/context.size.height;
		_timeline.setViewport(velocity: details.velocity.pixelsPerSecond.dy * scale, animate: true);
		// setState(() 
		// {	
		// 	_velocity = details.velocity.pixelsPerSecond.dy * scale;
		// });
	}

	void _pointerUp(PointerUpEvent details)
	{
		if(_touchA != null && _touchA.pointer == details.pointer)
		{
			_touchA = null;
		}
		if(_touchB != null && _touchB.pointer == details.pointer)
		{
			_touchB = null;
		}
	}

	void _pointerDown(PointerDownEvent details)
	{
		TouchData touch = new TouchData()
							..pointer = details.pointer
							..touchY = details.position.dy
							..moveY = details.position.dy
							..yearStart = _yearStart
							..yearEnd = _yearEnd;

		if(_touchA == null)
		{
			_touchA = touch;
		}
		else if(_touchB == null)
		{
			_touchB = touch;
		}

		// Swap them if touch A is below touch B
		if(_touchB != null && _touchB != null && _touchA.touchY > _touchB.touchY)
		{
			touch = _touchB;
			_touchB = _touchA;
			_touchA = touch;
		}
		print("DETAILS ${details.position.dy}");
	}

	void _pointerMove(PointerMoveEvent details)
	{
		if(_touchA != null && _touchA.pointer == details.pointer)
		{
			_touchA.moveY = details.position.dy;
		}
		else if(_touchB != null && _touchB.pointer == details.pointer)
		{
			_touchB.moveY = details.position.dy;
		}

		
		double devicePixelRatio = window.devicePixelRatio;
		
		// N.B. assumes full screen, no offset.
		double height = context.size.height;

		if(_touchA != null && _touchB != null)
		{
			// scale and pan
			double scaleA = (_touchA.yearEnd-_touchA.yearStart)/height;
			double start = _touchA.yearStart - (_touchA.moveY - _touchA.touchY) / scaleA;

			double scaleB = (_touchB.yearEnd-_touchB.yearStart)/height;
			double end = _touchB.yearEnd - (_touchB.moveY - _touchB.touchY) / scaleB;
			setState(() 
			{
				_yearStart = start;
				//_yearEnd = end;
			});

		}
		else if(_touchA != null)
		{
			// just pan
			double scaleA = (_touchA.yearEnd-_touchA.yearStart)/height;

			double fromTouchA = _touchA.yearStart + _touchA.touchY * scaleA;
			double toTouchA = _touchA.yearStart + _touchA.moveY * scaleA;

			// fromTouchA = _touchA.yearStart + _touchA.moveY * ((_touchA.yearEnd-_touchA.yearStart)/height);

			// fromTouchA/height - _touchA.moveY * (_touchA.yearEnd-_touchA.yearStart) = _touchA.yearStart/height;
			

			double scaleFrom = _touchA.touchY/height;
			double scaleAmount = (_touchA.moveY - _touchA.touchY)/height;
			double rangeChange = scaleAmount * scaleA;
			print("$fromTouchA $toTouchA ${_touchA.moveY} $height $devicePixelRatio");
			// double toTouchA = _touchA.yearStart + _touchA.moveY / scaleA;
			
			 double start = _touchA.yearStart - (toTouchA - fromTouchA);//(_touchA.moveY - _touchA.touchY) / scaleA;

			setState(() 
			{
				_yearStart = start;//_touchA.yearStart - (scaleFrom*rangeChange);
				//_yearEnd = end;
			});
		}
	}

	@override
	Widget build(BuildContext context) 
	{
		return new Stack(
			children:<Widget>
			[
				// new Positioned.fill(
				// 		child: new Listener(
				// 			onPointerUp: _pointerUp,
				// 			onPointerMove: _pointerMove,
				// 			onPointerDown: _pointerDown,
				// 			child: new TimelineRenderWidget(yearStart: _yearStart, yearEnd: _yearEnd)
				// 		)
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
	// final double yearStart;
	// final double yearEnd;
	// final double velocity;

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
