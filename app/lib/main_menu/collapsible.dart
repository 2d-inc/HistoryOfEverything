import 'package:flutter/material.dart';

class Collapsible extends StatefulWidget {
  final Widget child;
  final bool isCollapsed;
  Collapsible({this.child, this.isCollapsed, Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CollapsibleState();
}

class CollapsibleState extends State<Collapsible>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  static final Animatable<double> _sizeTween = Tween<double>(
    begin: 0.0,
    end: 1.0,
  );

  Animation<double> _sizeAnimation;

  initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    final CurvedAnimation curve =
        CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);
    _sizeAnimation = _sizeTween.animate(curve);
    if (!widget.isCollapsed) {
      _controller.forward(from: 1.0);
    }
  }

  void didUpdateWidget(covariant Collapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCollapsed != widget.isCollapsed) {
      if (widget.isCollapsed) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
        axisAlignment: 0.0,
        axis: Axis.vertical,
        sizeFactor: _sizeAnimation,
        child: widget.child);
  }
}
