import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

class Ticks
{
	static const double Margin = 20.0;
	static const double Width = 40.0;
	static const double Gutter = 45.0;
	static const double LabelPadLeft = 5.0;
	static const double LabelPadRight = 1.0;
	static const int TickDistance = 16;
	static const int TextTickDistance = 64;
	static const double TickSize = 15.0;
	static const double SmallTickSize = 5.0;

	void paint(PaintingContext context, Offset offset, double translation, double scale, double height)
	{
		final Canvas canvas = context.canvas;

		double bottom = height;
		double tickDistance = TickDistance.toDouble();
		double textTickDistance = TextTickDistance.toDouble();

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
		
		final Paint tickPaint = new Paint()..color = Color.fromRGBO(0, 0, 0, 0.3);
		final Paint smallTickPaint = new Paint()..color = Color.fromRGBO(0, 0, 0, 0.1);
		canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, Gutter, height), new Paint()..color = Color.fromRGBO(246, 246, 246, 0.95));
		
		
		Set<String> usedValues = new Set<String>();

		for(int i = 0; i < numTicks; i++)
		{
			tickOffset += scaledTickDistance;
			
			int tt = startingTickMarkValue.round();
			tt = -tt;
			int o = tickOffset.floor();
			if(tt%textTickDistance == 0)
			{
				canvas.drawRect(Rect.fromLTWH(offset.dx+Gutter-TickSize, offset.dy+height-o, TickSize, 1.0), tickPaint);
				ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
					textAlign:TextAlign.end,
					fontFamily: "Roboto",
					fontSize: 10.0
				))..pushStyle(new ui.TextStyle(color:const Color.fromRGBO(0, 0, 0, 0.6)));

				int value = tt.round().abs();

				NumberFormat formatter = NumberFormat.compact();
				String label = formatter.format(value);
				int digits = formatter.significantDigits;
				while(usedValues.contains(label) && digits < 10)
				{
					formatter.significantDigits = ++digits;
					label = formatter.format(value);
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
				tickParagraph.layout(new ui.ParagraphConstraints(width: Gutter-LabelPadLeft-LabelPadRight));			
				canvas.drawParagraph(tickParagraph, new Offset(offset.dx+LabelPadLeft-LabelPadRight, offset.dy + height - o - tickParagraph.height - 5));
			}
			else
			{
				canvas.drawRect(Rect.fromLTWH(offset.dx+Gutter-SmallTickSize, offset.dy+height-o, SmallTickSize, 1.0), smallTickPaint);
			}
			startingTickMarkValue += tickDistance;
		}
	}
}