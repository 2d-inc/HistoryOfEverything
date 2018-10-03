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
		_timeline.isInteracting = true;
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
		_timeline.isInteracting = false;
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
	static const List<Color> LineColors =
	[
		const Color.fromARGB(255, 125, 195, 184),
		const Color.fromARGB(255, 190, 224, 146),
		const Color.fromARGB(255, 238, 155, 75),
		const Color.fromARGB(255, 202, 79, 63),
		const Color.fromARGB(255, 128, 28, 15)
	];


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
		markNeedsLayout();
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

		double renderStart = _timeline.renderStart;
		double renderEnd = _timeline.renderEnd;
		double scale = size.height/(renderEnd-renderStart);

		//canvas.drawRect(new Offset(0.0, 0.0) & new Size(100.0, 100.0), new Paint()..color = Colors.red);
		_ticks.paint(context, offset, -renderStart*scale, scale, size.height);

		if(timeline.renderAssets != null)
		{
			canvas.save();
			for(TimelineEntryAsset asset in timeline.renderAssets)
			{
				if(asset.opacity > 0)
				{
					//ctx.globalAlpha = asset.opacity;
					double rs = 0.2+asset.scale*0.8;

					double w = asset.width * Timeline.AssetScreenScale;
					double h = asset.height * Timeline.AssetScreenScale;
					//ctx.drawImage(asset.image, width-w, item.assetY, w*rs, h*rs);
					canvas.drawImageRect(asset.image, Rect.fromLTWH(0.0, 0.0, asset.width, asset.height), Rect.fromLTWH(offset.dx + size.width - w, asset.y, w*rs, h*rs), new Paint()..isAntiAlias=true..filterQuality=ui.FilterQuality.low..color = Colors.white.withOpacity(asset.opacity));
					//ctx.rect(width-item.asset.width, item.assetY, item.asset.width*rs, item.asset.height*rs);
					//ctx.fill();
				}
			}
			canvas.restore();
		}
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
			canvas.drawPath(bubble, new Paint()..color = LineColors[depth%LineColors.length].withOpacity(item.opacity*item.labelOpacity));
			canvas.clipRect(new Rect.fromLTWH(BubblePadding, 0.0, textWidth, BubbleHeight));

			
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
