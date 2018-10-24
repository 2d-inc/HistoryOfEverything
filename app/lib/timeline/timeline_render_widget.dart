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
typedef TouchBubbleCallback(Bubble bubble);

class TimelineRenderWidget extends LeafRenderObjectWidget
{
	final Timeline timeline;
	final bool isActive;
	final MenuItemData focusItem;
	final TouchBubbleCallback touchBubble;
	final double topOverlap;
	TimelineRenderWidget({Key key, this.timeline, this.isActive, this.focusItem, this.touchBubble, this.topOverlap}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new TimelineRenderObject()
							..timeline = timeline
							..isActive = isActive
							..focusItem = focusItem
							..touchBubble = touchBubble
							..topOverlap = topOverlap;
	}

	@override
	void updateRenderObject(BuildContext context, covariant TimelineRenderObject renderObject)
	{
		renderObject
					..timeline = timeline
					..isActive = isActive
					..focusItem = focusItem
					..touchBubble = touchBubble
					..topOverlap = topOverlap;
	}
}


class Bubble
{
	TimelineEntry entry;
	Rect rect;
}

class TimelineRenderObject extends RenderBox
{
	static const List<Color> LineColors =
	[
		const Color.fromARGB(255, 125, 195, 184),
		const Color.fromARGB(255, 190, 224, 146),
		const Color.fromARGB(255, 238, 155, 75),
		const Color.fromARGB(255, 202, 79, 63),
		const Color.fromARGB(255, 128, 28, 15)
	];

	List<Bubble> _bubbles = new List<Bubble>();
	Ticks _ticks = new Ticks();
	Timeline _timeline;
	bool _isActive = false;
	MenuItemData _focusItem;

	double topOverlap = 0.0;
	TouchBubbleCallback _touchBubble;
	TouchBubbleCallback get touchBubble => _touchBubble;
	set touchBubble(TouchBubbleCallback value)
	{
		if(_touchBubble == value)
		{
			return;
		}
		_touchBubble = value;
	}
	
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
			if(_isActive)
			{
				markNeedsPaint();
			}
		};
		markNeedsLayout();
	}

	bool get isActive => _isActive;
	set isActive(bool value)
	{
		if(_isActive == value)
		{
			return;
		}
		_timeline.isActive = value;
		_isActive = value;
		if(_isActive)
		{
			markNeedsPaint();
			markNeedsLayout();
		}
	}

	MenuItemData get focusItem => _focusItem;
	set focusItem(MenuItemData value)
	{
		if(_focusItem == value)
		{
			return;
		}
		_focusItem = value;
		if(_focusItem == null || timeline == null)
		{
			return;
		}
		double padding = timeline.screenPaddingInTime(value.start, value.end);
		timeline.setViewport(start: value.start-padding, end:value.end+padding, animate:true);
	}

	@override
	bool get sizedByParent => true;
	
	@override
	bool hitTestSelf(Offset screenOffset)
	{
		for(Bubble bubble in _bubbles)
		{
			if(bubble.rect.contains(screenOffset))
			{
				if(_touchBubble != null)
				{
					_touchBubble(bubble);
				}
				return true;
			}
		}
		_touchBubble(null);
		return true;
	}

	@override
	void performResize() 
	{
		size = constraints.biggest;
	}

	@override
	void performLayout() 
	{
		if(_timeline != null)
		{
			_timeline.setViewport(height:size.height, animate:true);
		}
	}

	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;
		if(_timeline == null)
		{
			return;
		}

		_bubbles.clear();
		double renderStart = _timeline.renderStart;
		double renderEnd = _timeline.renderEnd;
		double scale = size.height/(renderEnd-renderStart);

		//canvas.drawRect(new Offset(0.0, 0.0) & new Size(100.0, 100.0), new Paint()..color = Colors.red);

		if(timeline.renderAssets != null)
		{
			canvas.save();	
			for(TimelineAsset asset in timeline.renderAssets)
			{
				if(asset.opacity > 0)
				{
					//ctx.globalAlpha = asset.opacity;
					double rs = 0.2+asset.scale*0.8;

					double w = asset.width * Timeline.AssetScreenScale;
					double h = asset.height * Timeline.AssetScreenScale;

					if(asset is TimelineImage)
					{
						canvas.drawImageRect(asset.image, Rect.fromLTWH(0.0, 0.0, asset.width, asset.height), Rect.fromLTWH(offset.dx + size.width - w, asset.y, w*rs, h*rs), new Paint()..isAntiAlias=true..filterQuality=ui.FilterQuality.low..color = Colors.white.withOpacity(asset.opacity));
					}
					else if(asset is TimelineNima && asset.actor != null)
					{
						Alignment alignment = Alignment.center;
						BoxFit fit = BoxFit.cover;

						nima.AABB bounds = asset.setupAABB;
						
						double contentHeight = bounds[3] - bounds[1];
						double contentWidth = bounds[2] - bounds[0];
						double x = -bounds[0] - contentWidth/2.0 - (alignment.x * contentWidth/2.0) + asset.offset;
						double y =  -bounds[1] - contentHeight/2.0 + (alignment.y * contentHeight/2.0);

						Offset renderOffset = new Offset(offset.dx + size.width - w, asset.y);
						Size renderSize = new Size(w*rs, h*rs);

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
						
						asset.actor.draw(canvas, asset.opacity);
						canvas.restore();
					}
				}
			}
			canvas.restore();
			//print("DREW ${timeline.renderAssets.length}");
		}

		canvas.save();
		canvas.clipRect(new Rect.fromLTWH(offset.dx, offset.dy+topOverlap, size.width, size.height));
		_ticks.paint(context, offset, -renderStart*scale, scale, size.height);
		canvas.restore();

		if(_timeline.entries != null)
		{
			canvas.save();
			canvas.clipRect(new Rect.fromLTWH(offset.dx + Timeline.GutterLeft, offset.dy, size.width-Timeline.GutterLeft, size.height));
			drawItems(context, offset, _timeline.entries, Timeline.MarginLeft-Timeline.DepthOffset*_timeline.renderOffsetDepth, scale, 0);
			canvas.restore();
		}
	}

	void drawItems(PaintingContext context, Offset offset, List<TimelineEntry> entries, double x, double scale, int depth)
	{
		final Canvas canvas = context.canvas;

		for(TimelineEntry item in entries)
		{
			if(!item.isVisible || item.y > size.height + Timeline.BubbleHeight || item.endY < -Timeline.BubbleHeight)
			{
				continue;
			}

			double legOpacity = item.legOpacity * item.opacity;
			canvas.drawCircle(new Offset(x + Timeline.LineWidth/2.0, item.y), Timeline.EdgeRadius, new Paint()..color = LineColors[depth%LineColors.length].withOpacity(item.opacity));
			if(legOpacity > 0.0)
			{
				Paint legPaint = new Paint()..color = LineColors[depth%LineColors.length].withOpacity(legOpacity);
				canvas.drawRect(new Offset(x, item.y) & new Size(Timeline.LineWidth, item.length), legPaint);
				canvas.drawCircle(new Offset(x + Timeline.LineWidth/2.0, item.y+item.length), Timeline.EdgeRadius, legPaint);
			}

			const double MaxLabelWidth = 1200.0;
			const double BubbleHeight = 50.0;
			const double BubblePadding = 20.0;

			ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
				textAlign:TextAlign.start,
				fontFamily: "Arial",
				fontSize: 18.0
			))..pushStyle(new ui.TextStyle(color:const Color.fromRGBO(255, 255, 255, 1.0)));

			builder.addText(item.label);
			ui.Paragraph labelParagraph = builder.build();
			labelParagraph.layout(new ui.ParagraphConstraints(width: MaxLabelWidth));			
			//canvas.drawParagraph(labelParagraph, new Offset(offset.dx + Gutter - labelParagraph.minIntrinsicWidth-2, offset.dy + height - o - labelParagraph.height - 5));

			double textWidth = labelParagraph.maxIntrinsicWidth*item.opacity*item.labelOpacity;
			// ctx.globalAlpha = labelOpacity*itemOpacity;
			// ctx.save();
			// let bubbleX = labelX-DepthOffset*renderOffsetDepth;
			double bubbleX = _timeline.renderLabelX-Timeline.DepthOffset*_timeline.renderOffsetDepth;
			double bubbleY = item.labelY-BubbleHeight/2.0;
			
			canvas.save();
			canvas.translate(bubbleX, bubbleY);
			Path bubble = makeBubblePath(textWidth + BubblePadding*2.0, BubbleHeight);
			canvas.drawPath(bubble, new Paint()..color = LineColors[depth%LineColors.length].withOpacity(item.opacity*item.labelOpacity*0.95));
			canvas.clipRect(new Rect.fromLTWH(BubblePadding, 0.0, textWidth, BubbleHeight));
			_bubbles.add(new Bubble()..entry=item..rect=Rect.fromLTWH(bubbleX, bubbleY, textWidth + BubblePadding*2.0, BubbleHeight));

			
			canvas.drawParagraph(labelParagraph, new Offset(BubblePadding, BubbleHeight/2.0-labelParagraph.height/2.0));
			canvas.restore();
			// if(item.asset != null)
			// {
			// 	canvas.drawImageRect(item.asset.image, Rect.fromLTWH(0.0, 0.0, item.asset.width, item.asset.height), Rect.fromLTWH(bubbleX + textWidth + BubblePadding*2.0, bubbleY, item.asset.width, item.asset.height), new Paint()..isAntiAlias=true..filterQuality=ui.FilterQuality.low);
			// }
			if(item.children != null)
			{
				drawItems(context, offset, item.children, x + Timeline.DepthOffset, scale, depth+1);
			}
		}
	}

	Path makeBubblePath(double width, double height)
	{
		const double ArrowSize = 19.0;
		const double CornerRadius = 10.0;
		
		const double circularConstant = 0.55;
		const double icircularConstant = 1.0 - circularConstant;

		Path path = new Path();

		path.moveTo(CornerRadius, 0.0);
		path.lineTo(width-CornerRadius, 0.0);
		path.cubicTo(
						width-CornerRadius+CornerRadius*circularConstant, 0.0, 
						width, CornerRadius*icircularConstant,
						width, CornerRadius);
		path.lineTo(width, height - CornerRadius);
		path.cubicTo(
						width, height - CornerRadius + CornerRadius * circularConstant,
						width - CornerRadius * icircularConstant, height,
						width - CornerRadius, height);
		path.lineTo(CornerRadius, height);
		path.cubicTo(
						CornerRadius * icircularConstant, height,
						0.0, height - CornerRadius * icircularConstant,
						0.0, height - CornerRadius);

		path.lineTo(0.0, height/2.0+ArrowSize/2.0);
		path.lineTo(-ArrowSize/2.0, height/2.0);
		path.lineTo(0.0, height/2.0-ArrowSize/2.0);

		path.lineTo(0.0, CornerRadius);

		path.cubicTo(
						0.0, CornerRadius * icircularConstant,
						CornerRadius * icircularConstant, 0.0,
						CornerRadius, 0.0);

		path.close();

		
		return path;
	}
}
