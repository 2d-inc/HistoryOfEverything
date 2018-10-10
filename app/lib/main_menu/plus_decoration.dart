import 'dart:math';
import 'package:flutter/widgets.dart';

class PlusDecoration extends Decoration
{
    final Color color;

    PlusDecoration(this.color);

    @override
    BoxPainter createBoxPainter([VoidCallback onChanged])
    {
        return new PlusPainter(color);
    }
}

class PlusPainter extends BoxPainter
{
    final Color color;

    PlusPainter(this.color);

    @override
    void paint(Canvas canvas, Offset offset, ImageConfiguration config)
    {
        canvas.save();
        Paint paint = new Paint()
                            ..strokeWidth=2.0
                            ..color = this.color
                            ..style=PaintingStyle.stroke;
        canvas.drawArc(offset & config.size, 0, pi*2, false, paint);
        Size vertRectSize = Size(2.0, 10.0);
        Offset vertRectOffset = offset + Offset(config.size.width/2.0 - vertRectSize.width/2.0, config.size.height/2.0-vertRectSize.height/2.0);
        canvas.drawRect(vertRectOffset&vertRectSize, paint..style=PaintingStyle.fill);
        Size horizRectSize = Size(10.0, 2.0);
        Offset horizRectOffset = offset + Offset(config.size.width/2.0 - horizRectSize.width/2.0, config.size.height/2.0-horizRectSize.height/2.0);
        canvas.drawRect(horizRectOffset&horizRectSize, paint..style=PaintingStyle.fill);
        canvas.restore();
    }
}