import 'dart:math';
import 'dart:ui';
import "dart:ui" as ui;

import 'package:flare/flare.dart' as flare;
import 'package:nima/nima.dart' as nima;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import "package:flutter/scheduler.dart";
import 'package:nima/nima/actor_image.dart' as nima;
import 'package:nima/nima/math/aabb.dart' as nima;
import 'package:flare/flare/actor_image.dart' as flare;
import 'package:flare/flare/math/aabb.dart' as flare;
import "package:timeline/timeline/timeline_entry.dart";


class TimelineEntryWidget extends LeafRenderObjectWidget
{
	final bool isActive;
	final TimelineEntry timelineEntry;
	TimelineEntryWidget({Key key, this.isActive, this.timelineEntry}): super(key: key);

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

	@override
	didUnmountRenderObject(covariant VignetteRenderObject renderObject)
	{
		renderObject
			..isActive = false
			..timelineEntry = null;
	}
}

class VignetteRenderObject extends RenderBox
{
	TimelineEntry _timelineEntry;
	bool _isActive = false;
	bool _firstUpdate = true;
	nima.FlutterActor _nimaActor;
	flare.FlutterActorArtboard _flareActor;
	
	TimelineEntry get timelineEntry => _timelineEntry;
	set timelineEntry(TimelineEntry value)
	{
		if(_timelineEntry == value)
		{
			return;
		}
		_timelineEntry = value;
		_firstUpdate = true;
		updateActor();
		updateRendering();
	}

	updateActor()
	{
		if(_timelineEntry == null)
		{
			_nimaActor?.dispose();
			_flareActor?.dispose();
			_nimaActor = null;
			_flareActor = null;
		}
		else
		{
			TimelineAsset asset = _timelineEntry.asset;
			if(asset is TimelineNima && asset.actor != null)
			{
				_nimaActor = asset.actor.makeInstance();
				asset.animation.apply(asset.animation.duration, _nimaActor, 1.0);
				_nimaActor.advance(0.0);
			}
			else if(asset is TimelineFlare && asset.actor != null)
			{
				_flareActor = asset.actor.makeInstance();
				asset.animation.apply(asset.animation.duration, _flareActor, 1.0);
				_flareActor.advance(0.0);
			}
		}
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
	bool hitTestSelf(Offset screenOffset)
	{
		if(_timelineEntry != null)
		{
			TimelineAsset asset = _timelineEntry.asset;
			if(asset is TimelineNima && asset.actor != null)
			{
				asset.animationTime = 0.0;
			}
			else if(asset is TimelineFlare && asset.actor != null)
			{
				asset.animationTime = 0.0;
			}
		} 
		return true;
	}

	@override
	void performResize() 
	{
		size = constraints.biggest;
	}

	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;
		TimelineAsset asset = _timelineEntry?.asset;
		
        if(_timelineEntry == null || asset == null)
		{
			return;
		}

		canvas.save();	

		double w = asset.width;
		double h = asset.height;

		if(asset is TimelineImage)
		{
			canvas.drawImageRect(asset.image, Rect.fromLTWH(0.0, 0.0, asset.width, asset.height), Rect.fromLTWH(offset.dx + size.width - w, asset.y, w, h), new Paint()..isAntiAlias=true..filterQuality=ui.FilterQuality.low..color = Colors.white.withOpacity(asset.opacity));
		}
		else if(asset is TimelineNima && _nimaActor != null)
		{
			Alignment alignment = Alignment.center;
			BoxFit fit = BoxFit.contain;

			nima.AABB bounds = asset.setupAABB;
			
			
			double contentHeight = bounds[3] - bounds[1];
			double contentWidth = bounds[2] - bounds[0];
			double x = -bounds[0] - contentWidth/2.0 - (alignment.x * contentWidth/2.0);
			double y =  -bounds[1] - contentHeight/2.0 + (alignment.y * contentHeight/2.0);

			Offset renderOffset = offset;
			Size renderSize = size;

			double scaleX = 1.0, scaleY = 1.0;

			canvas.save();		

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
			_nimaActor.draw(canvas, 1.0);

			canvas.restore();
		}
		else if(asset is TimelineFlare && _flareActor != null)
		{
			Alignment alignment = Alignment.center;
			BoxFit fit = BoxFit.contain;

			flare.AABB bounds = asset.setupAABB;
			double contentWidth = bounds[2] - bounds[0];
			double contentHeight = bounds[3] - bounds[1];
			double x = -bounds[0] - contentWidth/2.0 - (alignment.x * contentWidth/2.0);
			double y =  -bounds[1] - contentHeight/2.0 + (alignment.y * contentHeight/2.0);

			Offset renderOffset = offset;
			Size renderSize = size;

			double scaleX = 1.0, scaleY = 1.0;

			canvas.save();

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
			canvas.scale(scaleX, scaleY);
			canvas.translate(x, y);

			_flareActor.draw(canvas);
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
			_isFrameScheduled = true;
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
			return;
		}

		double elapsed = t - _lastFrameTime;
		_lastFrameTime = t;
		if(_timelineEntry != null)
		{
			TimelineAsset asset = _timelineEntry.asset;
			if(asset is TimelineNima && _nimaActor != null)
			{
				asset.animationTime += elapsed;
		
				if(asset.loop)
				{
					asset.animationTime %= asset.animation.duration;
				}
				asset.animation.apply(asset.animationTime, _nimaActor, 1.0);
				_nimaActor.advance(elapsed);
			}
			else if(asset is TimelineFlare && _flareActor != null)
			{
				if(_firstUpdate)
				{
					if(asset.intro != null)
					{
						asset.animation = asset.intro;
						asset.animationTime = -1.0;
					}
					_firstUpdate = false;
				}
				asset.animationTime += elapsed;
				if(asset.idleAnimations != null)
				{
					
					double phase = 0.0;
					for(flare.ActorAnimation animation in asset.idleAnimations)
					{
						animation.apply((asset.animationTime+phase)%animation.duration, _flareActor, 1.0);
						phase += 0.16;
					}
				}
				else
				{
					if(asset.intro == asset.animation && asset.animationTime >= asset.animation.duration)
					{
						asset.animationTime -= asset.animation.duration;
						asset.animation = asset.idle;
					}
					if(asset.loop && asset.animationTime >= 0)
					{
						asset.animationTime %= asset.animation.duration;
					}
					asset.animation.apply(asset.animationTime, _flareActor, 1.0);
				}
				_flareActor.advance(elapsed);
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