import 'dart:math';
import 'dart:ui';
import "dart:ui" as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import "package:flutter/scheduler.dart";
import 'package:nima/nima/actor_image.dart' as nima;
import 'package:nima/nima/math/aabb.dart' as nima;
import 'package:flare/flare/actor_image.dart' as flare;
import 'package:flare/flare/math/aabb.dart' as flare;
import 'package:timeline/timeline/timeline.dart';
import "package:timeline/timeline/timeline_entry.dart";

class MenuVignette extends LeafRenderObjectWidget
{
	final bool isActive;
	final Timeline timeline;
	final String assetId;
	final Color gradientColor;
	MenuVignette({Key key, this.gradientColor, this.isActive, this.timeline, this.assetId}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new MenuVignetteRenderObject()
							..timeline = timeline
							..assetId = assetId
							..gradientColor = gradientColor
							..isActive = isActive;
	}

	@override
	void updateRenderObject(BuildContext context, covariant MenuVignetteRenderObject renderObject)
	{
		renderObject
					..timeline = timeline
					..assetId = assetId
						..gradientColor = gradientColor
					..isActive = isActive;
	}
}

class MenuVignetteRenderObject extends RenderBox
{
	Timeline _timeline;
	String assetId;
	bool _isActive = false;
	bool _firstUpdate = true;
	Color gradientColor;
	
	Timeline get timeline => _timeline;
	set timeline(Timeline value)
	{
		if(_timeline == value)
		{
			return;
		}
		_timeline = value;
		_firstUpdate = true;
		updateRendering();
	}

	void updateRendering()
	{
		if(_isActive)
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

	TimelineEntry get timelineEntry
	{
		if(_timeline == null)
		{
			return null;
		}
		return _timeline.getById(assetId);
	}

	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;
		TimelineEntry entry = timelineEntry;
		if(entry == null)
		{
			return;
		}

		TimelineAsset asset = entry.asset;
		
		canvas.save();	

		double w = asset.width;// * Timeline.AssetScreenScale;
		double h = asset.height;// * Timeline.AssetScreenScale;

		if(asset is TimelineImage)
		{
			canvas.drawImageRect(asset.image, Rect.fromLTWH(0.0, 0.0, asset.width, asset.height), Rect.fromLTWH(offset.dx + size.width - w, asset.y, w, h), new Paint()..isAntiAlias=true..filterQuality=ui.FilterQuality.low..color = Colors.white.withOpacity(asset.opacity));
		}
		else if(asset is TimelineNima && asset.actor != null)
		{
			Alignment alignment = Alignment.topRight;
			BoxFit fit = BoxFit.cover;

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

			List<ui.Color> colors = <ui.Color>[gradientColor.withOpacity(0.0), gradientColor.withOpacity(0.9)];
			List<double> stops = <double>[0.0, 1.0];
			
			ui.Paint paint = new ui.Paint()
									..shader = new ui.Gradient.linear(new ui.Offset(0.0, offset.dy), new ui.Offset(0.0, offset.dy+150.0), colors, stops)
									..style = ui.PaintingStyle.fill;
			canvas.drawRect(offset & size, paint);
		}
		else if(asset is TimelineFlare && asset.actor != null)
		{
			Alignment alignment = Alignment.center;
			BoxFit fit = BoxFit.contain;

			flare.AABB bounds = asset.setupAABB;
			double contentWidth = bounds[2] - bounds[0];
			double contentHeight = bounds[3] - bounds[1];
			double x = -bounds[0] - contentWidth/2.0 - (alignment.x * contentWidth/2.0);
			double y =  -bounds[1] - contentHeight/2.0 + (alignment.y * contentHeight/2.0);

			Offset renderOffset = offset;
			Size renderSize = size;//new Size(w*rs, h*rs);

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
			canvas.scale(scaleX, scaleY);
			canvas.translate(x, y);

			asset.actor.draw(canvas, opacity:asset.opacity);
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
		TimelineEntry entry = timelineEntry;
		if(entry != null)
		{
			TimelineAsset asset = entry.asset;
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
			else if(asset is TimelineFlare && asset.actor != null)
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
				if(asset.intro == asset.animation && asset.animationTime >= asset.animation.duration)
				{
					asset.animationTime -= asset.animation.duration;
					asset.animation = asset.idle;
				}
				if(asset.loop && asset.animationTime >= 0)
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