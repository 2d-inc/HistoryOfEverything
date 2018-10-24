import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import "package:flutter/scheduler.dart";
import 'package:nima/nima/math/aabb.dart' as nima;
import 'package:nima/nima/actor_image.dart' as nima;
import 'package:timeline/main_menu/menu_data.dart';
import "dart:ui" as ui;
import "../colors.dart";

import 'package:timeline/timeline/ticks.dart';
import 'package:timeline/timeline/timeline.dart';

class ArticleVignette extends LeafRenderObjectWidget
{
	final bool isActive;
	final TimelineEntry timelineEntry;
	ArticleVignette({Key key, this.isActive, this.timelineEntry}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new VignetteRenderObject()
							..timelineEntry = timelineEntry
							..isActive = isActive;
	}

	@override
	void updateRenderObject(BuildContext context, covariant VignetteRenderObject renderObject)
	{
		renderObject
					..timelineEntry = timelineEntry
					..isActive = isActive;
	}
}

class VignetteRenderObject extends RenderBox
{
	TimelineEntry _timelineEntry;
	bool _isActive = false;
	
	TimelineEntry get timelineEntry => _timelineEntry;
	set timelineEntry(TimelineEntry value)
	{
		if(_timelineEntry == value)
		{
			return;
		}
		_timelineEntry = value;
		updateRendering();
	}

	void updateRendering()
	{
		if(_isActive && _timelineEntry != null)
		{
			markNeedsPaint();
			if(!_isFrameScheduled)
			{
				_isFrameScheduled = true;
				SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
			}
		}
		markNeedsLayout();
	}

	bool get isActive => _isActive;
	set isActive(bool value)
	{
		if(_isActive == value)
		{
			return;
		}
		_isActive = value;
		updateRendering();
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
		final Canvas canvas = context.canvas;
		if(_timelineEntry == null)
		{
			return;
		}

		//canvas.drawRect(new Offset(0.0, 0.0) & new Size(100.0, 100.0), new Paint()..color = Colors.red);

		TimelineAsset asset = _timelineEntry.asset;
		
		canvas.save();	

		double w = asset.width;// * Timeline.AssetScreenScale;
		double h = asset.height;// * Timeline.AssetScreenScale;

		if(asset is TimelineImage)
		{
			canvas.drawImageRect(asset.image, Rect.fromLTWH(0.0, 0.0, asset.width, asset.height), Rect.fromLTWH(offset.dx + size.width - w, asset.y, w, h), new Paint()..isAntiAlias=true..filterQuality=ui.FilterQuality.low..color = Colors.white.withOpacity(asset.opacity));
		}
		else if(asset is TimelineNima && asset.actor != null)
		{
			Alignment alignment = Alignment.center;
			BoxFit fit = BoxFit.contain;

			nima.AABB bounds = asset.setupAABB;
			
			
			double contentHeight = bounds[3] - bounds[1];
			double contentWidth = bounds[2] - bounds[0];
			double x = -bounds[0] - contentWidth/2.0 - (alignment.x * contentWidth/2.0);
			double y =  -bounds[1] - contentHeight/2.0 + (alignment.y * contentHeight/2.0);

			Offset renderOffset = offset;//new Offset(offset.dx + size.width - w, asset.y);
			Size renderSize = size;//new Size(w, h);

			double scaleX = 1.0, scaleY = 1.0;

			canvas.save();		
			
			//canvas.clipRect(renderOffset & renderSize);

			switch(fit)
			{
				case BoxFit.fill:
					scaleX = renderSize.width/contentWidth;
					scaleY = renderSize.height/contentHeight;
					break;
				case BoxFit.contain:
					double minScale = min(renderSize.width/contentWidth, renderSize.height/contentHeight);
					scaleX = scaleY = minScale;
					break;
				case BoxFit.cover:
					double maxScale = max(renderSize.width/contentWidth, renderSize.height/contentHeight);
					scaleX = scaleY = maxScale;
					break;
				case BoxFit.fitHeight:
					double minScale = renderSize.height/contentHeight;
					scaleX = scaleY = minScale;
					break;
				case BoxFit.fitWidth:
					double minScale = renderSize.width/contentWidth;
					scaleX = scaleY = minScale;
					break;
				case BoxFit.none:
					scaleX = scaleY = 1.0;
					break;
				case BoxFit.scaleDown:
					double minScale = min(renderSize.width/contentWidth, renderSize.height/contentHeight);
					scaleX = scaleY = minScale < 1.0 ? minScale : 1.0;
					break;
			}
			
			canvas.translate(renderOffset.dx + renderSize.width/2.0 + (alignment.x * renderSize.width/2.0), renderOffset.dy + renderSize.height/2.0 + (alignment.y * renderSize.height/2.0));
			canvas.scale(scaleX, -scaleY);
			canvas.translate(x, y);
			asset.actor.draw(canvas, 1.0);

			canvas.restore();
		}
		canvas.restore();
	}


	bool _isFrameScheduled = false;
	double _lastFrameTime = 0.0;

	void beginFrame(Duration timeStamp) 
	{
		_isFrameScheduled = false;
		final double t = timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
		if(_lastFrameTime == 0)
		{
			_lastFrameTime = t;
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
			return;
		}

		double elapsed = t - _lastFrameTime;
		_lastFrameTime = t;
		if(_timelineEntry != null)
		{
			TimelineAsset asset = _timelineEntry.asset;
			if(asset is TimelineNima && asset.actor != null)
			{
				asset.animationTime += elapsed;
				if(asset.loop)
				{
					asset.animationTime %= asset.animation.duration;
				}
				asset.animation.apply(asset.animationTime, asset.actor, 1.0);
				asset.actor.advance(elapsed);
			}
		} 

		markNeedsPaint();
		if(isActive && !_isFrameScheduled)
		{
			_isFrameScheduled = true;
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
		}
	}

}