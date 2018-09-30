import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class TickData
{
	int value;
	int offset;	
}

class Ticks
{
	static const double Margin = 20.0;
	static const double Width = 40.0;
	static const double Gutter = 45.0;
	static const int TickDistance = 16;
	static const int TextTickDistance = 64;
	static const double TickSize = 15.0;
	static const double SmallTickSize = 5.0;

	void paint(PaintingContext context, Offset offset, double translation, double scale, double height)
	{
		final Canvas canvas = context.canvas;

		double left = offset.dx - Margin + Gutter;
		double bottom = height + Margin;
		double tickDistance = TickDistance.toDouble();
		double textTickDistance = TextTickDistance.toDouble();

		double scaledTickDistance = tickDistance * scale;
		while(scaledTickDistance < TickDistance)
		{
			scaledTickDistance *= 2;
			tickDistance *= 2;
			textTickDistance *= 2;
		}
		int numTicks = (height / scaledTickDistance).ceil()+2;

		// Figure out the position of the top left corner of the screen
		double tickOffset = 0.0;
		double startingTickMarkValue = 0.0;

		double x = ((left-translation)/scale);
		startingTickMarkValue = x-(x%tickDistance);
		tickOffset = -(x%tickDistance)*scale-scaledTickDistance;

		// Move back by one tick.
		tickOffset -= scaledTickDistance;
		startingTickMarkValue -= tickDistance;

		canvas.save();
		
		final Paint tickPaint = new Paint()..color = Color.fromRGBO(0, 0, 0, 0.3);
		final Paint smallTickPaint = new Paint()..color = Color.fromRGBO(0, 0, 0, 0.1);

		//canvas.drawRect(new Offset(0.0, 0.0) & new Size(100.0, 100.0), new Paint()..color = Colors.red);
		//ctx.fillStyle = "rgba(0,0,0,0.1)";
		//ctx.font = (10*ss)+"px Arial";
		canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, Gutter, height), smallTickPaint);
		//ctx.translate(0, height);

		//List<TickData> marks = new List<TickData>();
		
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
					textAlign:TextAlign.start,
					fontFamily: "Arial",
					fontSize: 10.0
				))..pushStyle(new ui.TextStyle(color:const Color.fromRGBO(0, 0, 0, 0.6)));
				builder.addText((tt/1000000).toStringAsFixed(2));
				ui.Paragraph tickParagraph = builder.build();
				tickParagraph.layout(new ui.ParagraphConstraints(width: Gutter));
				
				canvas.drawParagraph(tickParagraph, new Offset(offset.dx + Gutter - tickParagraph.minIntrinsicWidth-2, offset.dy + height - o - tickParagraph.height - 5));
			
				//marks.add(new TickData()..offset = o..value = tt);
				
			}
			else
			{
				canvas.drawRect(Rect.fromLTWH(offset.dx+Gutter-SmallTickSize, offset.dy+height-o, SmallTickSize, 1.0), smallTickPaint);
			}
			startingTickMarkValue += tickDistance;
		}
	}
}