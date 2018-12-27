import 'package:flutter/material.dart';

/// This widget is used to animate the header above [SearchWidget] so that it
/// smoothly collapses and expands when a change in the state is detected.
class Collapsible extends StatefulWidget {
  final Widget child;
  final bool isCollapsed;
  Collapsible({this.child, this.isCollapsed, Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CollapsibleState();
}

/// This [State] uses the [SingleTickerProviderStateMixin] to add [vsync] to it.
/// This allows the animation to run smoothly and avoids consuming unnecessary resources.
class CollapsibleState extends State<Collapsible>
    with SingleTickerProviderStateMixin {
  /// The [AnimationController] is a Flutter Animation object that generates a new value
  /// whenever the hardware is ready to draw a new frame.
  AnimationController _controller;
  /// Since the above object interpolates only between 0 and 1, but we'd rather apply a curve to the current
  /// animation, we're providing a custom [Tween] that allows to build more advanced animations, as seen in [initState()].
  static final Animatable<double> _sizeTween = Tween<double>(
    begin: 0.0,
    end: 1.0,
  );

  /// The [Animation] object itself, which is required by the [SizeTransition] widget in the [build()] method.
  Animation<double> _sizeAnimation;

  /// Here we initialize the fields described above, and set up the widget to its initial state.
  @override
  initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    /// This curve is controlled by [_controller]. 
    final CurvedAnimation curve =
        CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);
    /// [_sizeAnimation] will interpolate using this curve - [Curves.fastOutSlowIn].
    _sizeAnimation = _sizeTween.animate(curve);
    /// Sanity check.
    if (!widget.isCollapsed) {
      _controller.forward(from: 1.0);
    }
  }

  /// Whenever a new value is detected, update the animation accordingly.
  @override
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

  /// Clean up the resources.  
  @override
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
