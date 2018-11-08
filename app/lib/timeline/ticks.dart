import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:timeline/timeline/timeline.dart';

class Ticks
{
	static const double Margin = 20.0;
	static const double Width = 40.0;
	static const double LabelPadLeft = 5.0;
	static const double LabelPadRight = 1.0;
	static const int TickDistance = 16;
	static const int TextTickDistance = 64;
	static const double TickSize = 15.0;
	static const double SmallTickSize = 5.0;

	void paint(PaintingContext context, Offset offset, double translation, double scale, double height, Timeline timeline)
	{
		final Canvas canvas = context.canvas;

		double bottom = height;
		double tickDistance = TickDistance.toDouble();
		double textTickDistance = TextTickDistance.toDouble();
		double gutterWidth = timeline.gutterWidth;

		double scaledTickDistance = tickDistance * scale;

		if(scaledTickDistance > 2*TickDistance)
		{
			while(scaledTickDistance > 2*TickDistance && tickDistance >= 2.0)
			{
				scaledTickDistance /= 2.0;
				tickDistance /= 2.0;
				textTickDistance /= 2.0;
			}
		}
		else
		{
			while(scaledTickDistance < TickDistance)
			{
				scaledTickDistance *= 2.0;
				tickDistance *= 2.0;
				textTickDistance *= 2.0;
			}
		}
		int numTicks = (height / scaledTickDistance).ceil()+2;
		if(scaledTickDistance > TextTickDistance)
		{
			textTickDistance = tickDistance;
		}
		// Figure out the position of the top left corner of the screen
		double tickOffset = 0.0;
		double startingTickMarkValue = 0.0;

		double y = ((translation-bottom)/scale);
		startingTickMarkValue = y-(y%tickDistance);
		tickOffset = -(y%tickDistance)*scale-scaledTickDistance;

		// Move back by one tick.
		tickOffset -= scaledTickDistance;
		startingTickMarkValue -= tickDistance;

		//canvas.save();
		
		// final Paint tickPaint = new Paint()..color = Color.fromRGBO(0, 0, 0, 0.3);
		// final Paint smallTickPaint = new Paint()..color = Color.fromRGBO(0, 0, 0, 0.1);
		
		List<TickColors> tickColors = timeline.tickColors;
		if(tickColors != null && tickColors.length > 0)
		{
			double rangeStart = tickColors.first.start;
			double range = tickColors.last.start - tickColors.first.start;
			List<ui.Color> colors = <ui.Color>[];
			List<double> stops = <double>[];
			for(TickColors bg in tickColors)
			{
				colors.add(bg.background);
				stops.add((bg.start-rangeStart)/range);
			}
			double s = timeline.computeScale(timeline.renderStart, timeline.renderEnd);
			double y1 = (tickColors.first.start-timeline.renderStart) * s;
			double y2 = (tickColors.last.start-timeline.renderStart) * s;

			// Fill Background.
			ui.Paint paint = new ui.Paint()
										..shader = new ui.Gradient.linear(new ui.Offset(0.0, y1), new ui.Offset(0.0, y2), colors, stops)
										..style = ui.PaintingStyle.fill;

			if(y1 > offset.dy)
			{
				canvas.drawRect(new Rect.fromLTWH(offset.dx, offset.dy, gutterWidth, y1-offset.dy+1.0), new ui.Paint()..color = tickColors.first.background);
			}
			if(y2 < offset.dy+height)
			{
				canvas.drawRect(new Rect.fromLTWH(offset.dx, y2-1, gutterWidth, (offset.dy+height)-y2), new ui.Paint()..color = tickColors.last.background);
			}
			canvas.drawRect(new Rect.fromLTWH(offset.dx, y1, gutterWidth, y2-y1), paint);
			
			//print("SIZE ${new Rect.fromLTWH(offset.dx, y1, size.width, y2-y1)}");
		}
		else
		{
			canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, gutterWidth, height), new Paint()..color = Color.fromRGBO(246, 246, 246, 0.95));
		}
		
		
		Set<String> usedValues = new Set<String>();

		for(int i = 0; i < numTicks; i++)
		{
			tickOffset += scaledTickDistance;

			int tt = startingTickMarkValue.round();
			tt = -tt;
			int o = tickOffset.floor();
			TickColors colors = timeline.findTickColors(offset.dy+height-o);
			if(tt%textTickDistance == 0)
			{
				canvas.drawRect(Rect.fromLTWH(offset.dx+gutterWidth-TickSize, offset.dy+height-o, TickSize, 1.0), new Paint()..color = colors.long);
				ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
					textAlign:TextAlign.end,
					fontFamily: "Roboto",
					fontSize: 10.0
				))..pushStyle(new ui.TextStyle(color:colors.text));//const Color.fromRGBO(0, 0, 0, 0.6)));

				int value = tt.round().abs();
				String label;
				if(value < 9000)
				{
					label = value.toStringAsFixed(0);
				}
				else
				{
					NumberFormat formatter = NumberFormat.compact();
					label = formatter.format(value);
					int digits = formatter.significantDigits;
					while(usedValues.contains(label) && digits < 10)
					{
						formatter.significantDigits = ++digits;
						label = formatter.format(value);
					}
				}
				usedValues.add(label);
				// int valueAbs = tt.round().abs();
				// if(valueAbs > 1000000000)
				// {
				// 	double v = (valueAbs/100000000.0).floorToDouble()/10.0;
					
				// 	label = (valueAbs/1000000000).toStringAsFixed(v == v.floorToDouble() ? 0 : 1) + "B";
				// }
				// else if(valueAbs > 1000000)
				// {
				// 	double v = (valueAbs/100000.0).floorToDouble()/10.0;
				// 	label = (valueAbs/1000000).toStringAsFixed(v == v.floorToDouble() ? 0 : 1) + "M";
				// }
				// else if(valueAbs > 10000) // N.B. < 10,000
				// {
				// 	double v = (valueAbs/100.0).floorToDouble()/10.0;
				// 	label = (valueAbs/1000).toStringAsFixed(v == v.floorToDouble() ? 0 : 1) + "k";
				// }
				// else
				// {
				// 	label = valueAbs.toStringAsFixed(0);
				// }
				builder.addText(label);
				ui.Paragraph tickParagraph = builder.build();
				tickParagraph.layout(new ui.ParagraphConstraints(width: gutterWidth-LabelPadLeft-LabelPadRight));			
				canvas.drawParagraph(tickParagraph, new Offset(offset.dx+LabelPadLeft-LabelPadRight, offset.dy + height - o - tickParagraph.height - 5));
			}
			else
			{
				canvas.drawRect(Rect.fromLTWH(offset.dx+gutterWidth-SmallTickSize, offset.dy+height-o, SmallTickSize, 1.0), new Paint()..color = colors.short);
			}
			startingTickMarkValue += tickDistance;
		}
	}
}