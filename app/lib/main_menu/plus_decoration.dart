import 'dart:math';
import 'package:flutter/widgets.dart';

class PlusDecoration extends Decoration {
  final Color color;
  final double expandValue;

  PlusDecoration(this.color, this.expandValue);

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return PlusPainter(color, expandValue);
  }
}

class PlusPainter extends BoxPainter {
  final Color color;
  final double expandValue;

  PlusPainter(this.color, this.expandValue);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration config) {
    canvas.save();
    Paint paint = Paint()
      ..strokeWidth = 2.0
      ..color = this.color
      ..style = PaintingStyle.stroke;
    canvas.drawArc(offset & config.size, 0, pi * 2, false, paint);

    // Calculate the size of the vertical pluse sign based on the animation value.
    Size vertRectSize = Size(2.0, (1 - expandValue) * 10.0);
    Offset vertRectOffset = offset +
        Offset(config.size.width / 2.0 - vertRectSize.width / 2.0,
            config.size.height / 2.0 - vertRectSize.height / 2.0);
    canvas.drawRect(
        vertRectOffset & vertRectSize, paint..style = PaintingStyle.fill);

    Size horizRectSize = Size(10.0, 2.0);
    Offset horizRectOffset = offset +
        Offset(config.size.width / 2.0 - horizRectSize.width / 2.0,
            config.size.height / 2.0 - horizRectSize.height / 2.0);
    canvas.drawRect(
        horizRectOffset & horizRectSize, paint..style = PaintingStyle.fill);

    canvas.restore();
  }
}
