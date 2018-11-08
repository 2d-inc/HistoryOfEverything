import 'dart:math';
import 'dart:ui';
import "dart:ui" as ui;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nima/nima/actor_image.dart' as nima;
import 'package:nima/nima/math/aabb.dart' as nima;
import 'package:flare/flare/actor_image.dart' as flare;
import 'package:flare/flare/math/aabb.dart' as flare;
import 'package:timeline/main_menu/menu_data.dart';
import 'package:timeline/timeline/ticks.dart';
import 'package:timeline/timeline/timeline.dart';
import 'package:timeline/timeline/timeline_entry.dart';

typedef TouchBubbleCallback(TapTarget bubble);
typedef TouchEntryCallback(TimelineEntry entry);

class TimelineRenderWidget extends LeafRenderObjectWidget
{
	final MenuItemData focusItem;
	final TouchBubbleCallback touchBubble;
	final TouchEntryCallback touchEntry;
	final double topOverlap;
    final Timeline timeline; 

	TimelineRenderWidget({Key key, this.focusItem, this.touchBubble, this.touchEntry, this.topOverlap, this.timeline}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new TimelineRenderObject()
                            ..timeline = timeline
							..touchBubble = touchBubble
							..touchEntry = touchEntry
							..focusItem = focusItem
							..topOverlap = topOverlap;
	}

	@override
	void updateRenderObject(BuildContext context, covariant TimelineRenderObject renderObject)
	{
		renderObject
					..timeline = timeline
					..focusItem = focusItem
					..touchBubble = touchBubble
					..touchEntry = touchEntry
					..topOverlap = topOverlap;
	}

	@override
	didUnmountRenderObject(covariant TimelineRenderObject renderObject)
	{
		renderObject.timeline.isActive = false;
	}
}


class TapTarget
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

	List<TapTarget> _tapTargets = new List<TapTarget>();
	Ticks _ticks = new Ticks();
	Timeline _timeline;
	MenuItemData _focusItem;
	Rect _nextEntryRect;

	double topOverlap = 0.0;
	TouchBubbleCallback touchBubble;
	TouchEntryCallback touchEntry;
	
	Timeline get timeline => _timeline;
	set timeline(Timeline value)
	{
		if(_timeline == value)
		{
			return;
		}
		_timeline = value;
        _timeline.onNeedPaint = markNeedsPaint;
        markNeedsPaint();
		markNeedsLayout();
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
		
		if(value.pad)
		{
			double topPadding = timeline.screenPaddingInTime(topOverlap+value.padTop, value.start, value.end);
			double bottomPadding = timeline.screenPaddingInTime(value.padBottom, value.start, value.end);
			timeline.setViewport(start: value.start-topPadding, end:value.end+bottomPadding, animate:true);
		}
		else
		{
			timeline.setViewport(start: value.start, end:value.end, animate:true);
		}
		
	}

	@override
	bool get sizedByParent => true;
	
	@override
	bool hitTestSelf(Offset screenOffset)
	{
		if(_timeline.nextEntryOpacity > 0.1 && timeline.nextEntry != null && _nextEntryRect != null && _nextEntryRect.contains(screenOffset))
		{
			touchEntry(timeline.nextEntry);
		}
		else
		{
			touchEntry(null);
			for(TapTarget bubble in _tapTargets.reversed)
			{
				if(bubble.rect.contains(screenOffset))
				{
					if(touchBubble != null)
					{
						touchBubble(bubble);
					}
					return true;
				}
			}
		}
		touchBubble(null);


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

		List<TimelineBackgroundColor> backgroundColors = timeline.backgroundColors;
		if(backgroundColors != null && backgroundColors.length > 0)
		{
			double rangeStart = backgroundColors.first.start;
			double range = backgroundColors.last.start - backgroundColors.first.start;
			List<ui.Color> colors = <ui.Color>[];
			List<double> stops = <double>[];
			for(TimelineBackgroundColor bg in backgroundColors)
			{
				colors.add(bg.color);
				stops.add((bg.start-rangeStart)/range);
			}
			double s = timeline.computeScale(timeline.renderStart, timeline.renderEnd);
			double y1 = (backgroundColors.first.start-timeline.renderStart) * s;
			double y2 = (backgroundColors.last.start-timeline.renderStart) * s;

			// Fill Background.
			ui.Paint paint = new ui.Paint()
										..shader = new ui.Gradient.linear(new ui.Offset(0.0, y1), new ui.Offset(0.0, y2), colors, stops)
										..style = ui.PaintingStyle.fill;

			if(y1 > offset.dy)
			{
				canvas.drawRect(new Rect.fromLTWH(offset.dx, offset.dy, size.width, y1-offset.dy+1.0), new ui.Paint()..color = backgroundColors.first.color);
			}
			canvas.drawRect(new Rect.fromLTWH(offset.dx, y1, size.width, y2-y1), paint);
			
			//print("SIZE ${new Rect.fromLTWH(offset.dx, y1, size.width, y2-y1)}");
		}
		_tapTargets.clear();
		double renderStart = _timeline.renderStart;
		double renderEnd = _timeline.renderEnd;
		double scale = size.height/(renderEnd-renderStart);

		//canvas.drawRect(new Offset(0.0, 0.0) & new Size(100.0, 100.0), new Paint()..color = Colors.red);

		if(timeline.renderAssets != null)
		{
			canvas.save();
			canvas.clipRect(offset & size);
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
						_tapTargets.add(new TapTarget()..entry=asset.entry..rect=renderOffset & renderSize);
					}
					else if(asset is TimelineFlare && asset.actor != null)
					{
						Alignment alignment = Alignment.center;
						BoxFit fit = BoxFit.cover;

						flare.AABB bounds = asset.setupAABB;
						double contentWidth = bounds[2] - bounds[0];
						double contentHeight = bounds[3] - bounds[1];
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
						canvas.scale(scaleX, scaleY);
						canvas.translate(x, y);

						asset.actor.draw(canvas, opacity:asset.opacity);
						canvas.restore();
						_tapTargets.add(new TapTarget()..entry=asset.entry..rect=renderOffset & renderSize);
					}
				}
			}
			canvas.restore();
		}

		canvas.save();
		canvas.clipRect(new Rect.fromLTWH(offset.dx, offset.dy+topOverlap, size.width, size.height));
		_ticks.paint(context, offset, -renderStart*scale, scale, size.height, timeline);
		canvas.restore();

		if(_timeline.entries != null)
		{
			canvas.save();
			canvas.clipRect(new Rect.fromLTWH(offset.dx + Timeline.GutterLeft, offset.dy, size.width-Timeline.GutterLeft, size.height));
			drawItems(context, offset, _timeline.entries, Timeline.MarginLeft-Timeline.DepthOffset*_timeline.renderOffsetDepth, scale, 0);
			canvas.restore();
		}

		_nextEntryRect = null;
		if(_timeline.nextEntry != null && _timeline.nextEntryOpacity > 0.0)
		{
			Color color = Color.fromRGBO(69, 211, 197, _timeline.nextEntryOpacity);
			double pageSize = (_timeline.renderEnd-_timeline.renderStart);
			double pageReference = _timeline.renderEnd;//_timeline.renderStart + pageSize/2.0;

			const double MaxLabelWidth = 1200.0;
			ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
				textAlign:TextAlign.start,
				fontFamily: "Roboto",
				fontSize: 20.0
			))..pushStyle(new ui.TextStyle(color:color));

			builder.addText(_timeline.nextEntry.label);
			ui.Paragraph labelParagraph = builder.build();
			labelParagraph.layout(new ui.ParagraphConstraints(width: MaxLabelWidth));	

			double y = offset.dy + size.height - 200.0;
			double x = offset.dx + size.width/2.0 - labelParagraph.maxIntrinsicWidth/2.0;
			canvas.drawParagraph(labelParagraph, new Offset(x, y));
			y += labelParagraph.height;

			_nextEntryRect = new Rect.fromLTWH(x, y, labelParagraph.maxIntrinsicWidth, offset.dy+size.height-y);


			const double radius = 25.0;
			x = offset.dx + size.width/2.0;
			y += 15+radius;
			canvas.drawCircle(new Offset(x, y), radius, new Paint()..color=color..style=PaintingStyle.fill);
			_nextEntryRect.expandToInclude(Rect.fromLTWH(x-radius, y-radius, radius*2.0, radius*2.0));
			Path path = new Path();
			double arrowSize = 6.0;
			path.moveTo(offset.dx + size.width/2.0-arrowSize, y-arrowSize+arrowSize/2.0);
			path.lineTo(offset.dx + size.width/2.0, y+arrowSize/2.0);
			path.lineTo(offset.dx + size.width/2.0+arrowSize, y-arrowSize+arrowSize/2.0);
			canvas.drawPath(path, new  Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=2.0);
			y += 15+radius;


			builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
				textAlign:TextAlign.center,
				fontFamily: "Roboto",
				fontSize: 14.0,
				lineHeight: 1.428
			))..pushStyle(new ui.TextStyle(color:color));


			double timeUntil = _timeline.nextEntry.start - pageReference;
			double pages = timeUntil/pageSize;
			NumberFormat formatter = new NumberFormat.compact();
			String pagesFormatted = formatter.format(pages);
			String until = "in " + TimelineEntry.formatYears(timeUntil).toLowerCase() + "\n($pagesFormatted page scrolls)";
			builder.addText(until);
			labelParagraph = builder.build();
			labelParagraph.layout(new ui.ParagraphConstraints(width: size.width));			
			canvas.drawParagraph(labelParagraph, new Offset(offset.dx, y));
			y += labelParagraph.height;

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
			const double BubbleHeight = 55.0;
			const double BubblePadding = 24.0;

			ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
				textAlign:TextAlign.start,
				fontFamily: "Roboto",
				fontSize: 20.0
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
			canvas.drawPath(bubble, new Paint()..color = LineColors[depth%LineColors.length].withOpacity(item.opacity*item.labelOpacity));
			canvas.clipRect(new Rect.fromLTWH(BubblePadding, 0.0, textWidth, BubbleHeight));
			_tapTargets.add(new TapTarget()..entry=item..rect=Rect.fromLTWH(bubbleX, bubbleY, textWidth + BubblePadding*2.0, BubbleHeight));

			
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
