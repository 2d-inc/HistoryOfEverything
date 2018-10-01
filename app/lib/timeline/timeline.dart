import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import "package:flutter/scheduler.dart";
import "dart:ui" as ui;

typedef PaintCallback();

class Timeline
{
	double _start = 0.0;
	double _end = 0.0;
	double _renderStart;
	double _renderEnd;
	double _velocity = 0.0;
	double _lastFrameTime = 0.0;
	double _height = 0.0;

	PaintCallback onNeedPaint;
	double get start => _start;
	double get end => _end;
	double get renderStart => _renderStart;
	double get renderEnd => _renderEnd;

	static const double MoveSpeed = 20.0;
	static const double Deceleration = 9.0;

	Timeline()
	{
		setViewport(start: -1000.0, end: 100.0);
	}

	void setViewport({double start = double.maxFinite, double end = double.maxFinite, double height = double.maxFinite, double velocity = double.maxFinite, bool animate = false})
	{
		if(start != double.maxFinite)
		{
			_start = start;
		}
		if(end != double.maxFinite)
		{
			_end = end;
		}
		if(height != double.maxFinite)
		{
			_height = height;
		}
		if(velocity != double.maxFinite)
		{
			_velocity = velocity;
		}
		if(!animate)
		{
			_renderStart = start;
			_renderEnd = end;
			if(onNeedPaint != null)
			{
				onNeedPaint();
			}
		}
		else
		{
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
		}
	}

	void beginFrame(Duration timeStamp) 
	{
		final double t = timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
		if(_lastFrameTime == 0)
		{
			_lastFrameTime = t;
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
			return;
		}

		double elapsed = t - _lastFrameTime;
		_lastFrameTime = t;

		if(!advance(elapsed))
		{
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
		}

		if(onNeedPaint != null)
		{
			onNeedPaint();
		}
	}

	bool advance(double elapsed)
	{
		double scale = _height/(_renderEnd-_renderStart);

		// Attenuate velocity and displace targets.
		_velocity *= 1.0 - min(1.0, elapsed*Deceleration);
		double displace = _velocity*elapsed;
		_start -= displace;
		_end -= displace;

		// Animate movement.
		double speed = min(1.0, elapsed*MoveSpeed);
		double ds = _start - _renderStart;
		double de = _end - _renderEnd;
		
		bool doneRendering = true;
		bool scaling = true;
		if((ds*scale).abs() < 1.0 && (de*scale).abs() < 1.0)
		{
			scaling = false;
			_renderStart = _start;
			_renderEnd = _end;
		}
		else
		{
			doneRendering = false;
			_renderStart += ds*speed;
			_renderEnd += de*speed;
		}
		
		return doneRendering;
	}
}