import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import "../colors.dart";

typedef GoBackCallback();
typedef ArticleVisibilityChanged(bool isVisible);

class ArticleWidget extends StatefulWidget  
{
	final GoBackCallback goBack;
	final bool show;
	final ArticleVisibilityChanged visibilityChanged;
	ArticleWidget({this.goBack, this.show, this.visibilityChanged, Key key}) : super(key: key);

	@override
	 _ArticleWidgetState createState() => new _ArticleWidgetState();
}

class _ArticleWidgetState extends State<ArticleWidget> with SingleTickerProviderStateMixin
{
	AnimationController _controller;
	static final Animatable<Offset> _slideTween = Tween<Offset>(
		begin: const Offset(0.0, 0.0),
		end: const Offset(1.0, 0.0),
	).chain(CurveTween(
		curve: Curves.fastOutSlowIn,
	));
	Animation<Offset> _articleOffset;

	initState()
	{
		super.initState();

		_controller = AnimationController(
			vsync: this,
			duration: const Duration(milliseconds: 200),
		);
		_articleOffset = _controller.drive(_slideTween);
		if(widget.show)
		{
			_controller.reverse();
		}
		else
		{
			_controller.forward();
		}					
	}

	void didUpdateWidget(covariant ArticleWidget oldWidget) 
	{ 
		super.didUpdateWidget(oldWidget);
		if(oldWidget.show != widget.show)
		{
			if(widget.show)
			{
				_controller.reverse().whenComplete(()
				{
					setState(() 
					{
						widget.visibilityChanged(true);
					});
				});
			}
			else
			{
				_controller.forward().whenComplete(()
				{
					setState(() 
					{
						widget.visibilityChanged(false);
					});
				});
			}
		}
	}

    @override
    Widget build(BuildContext context) 
	{
		EdgeInsets devicePadding = MediaQuery.of(context).padding;
		return SlideTransition(
			position: _articleOffset, 
			child:Container(
				color: background,
				child: new Stack(
					children:<Widget>
					[
						//new TimelineRenderWidget(timeline: _timeline, isActive:widget.isActive, focusItem:widget.focusItem, touchBubble:onTouchBubble),
						new Column(
						children: <Widget>[
							Container(
								height:devicePadding.top,
								color:Color.fromRGBO(238, 240, 242, 0.81)
							),
							Container(
								color:Color.fromRGBO(238, 240, 242, 0.81), 
								height: 56.0,
								width: double.infinity,
								child: new IconButton(
									alignment: Alignment.centerLeft,
									icon: new Icon(Icons.arrow_back),
									onPressed: () { this.widget.goBack(); },
								)
							)
						]
					)
					]
				)
			)
		);
	}

}