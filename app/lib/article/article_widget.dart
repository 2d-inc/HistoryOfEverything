import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:timeline/article/article_vignette.dart';
import 'package:timeline/timeline/timeline.dart';
import "../colors.dart";
import "package:flutter/services.dart" show rootBundle;

typedef GoBackCallback();
typedef ArticleVisibilityChanged(bool isVisible);

class ArticleWidget extends StatefulWidget  
{
	final GoBackCallback goBack;
	final bool show;
	final ArticleVisibilityChanged visibilityChanged;
	final TimelineEntry article;
	ArticleWidget({this.goBack, this.show, this.visibilityChanged, this.article, Key key}) : super(key: key);

	@override
	 _ArticleWidgetState createState() => new _ArticleWidgetState();
}

String formatYearsAgo(int value)
{
	String label;
	int valueAbs = value.abs();
	if(valueAbs > 1000000000)
	{
		double v = (valueAbs/100000000.0).floorToDouble()/10.0;
		
		label = (valueAbs/1000000000).toStringAsFixed(v == v.floorToDouble() ? 0 : 1) + " Billion";
	}
	else if(valueAbs > 1000000)
	{
		double v = (valueAbs/100000.0).floorToDouble()/10.0;
		label = (valueAbs/1000000).toStringAsFixed(v == v.floorToDouble() ? 0 : 1) + " Million";
	}
	else if(valueAbs > 10000) // N.B. < 10,000
	{
		double v = (valueAbs/100.0).floorToDouble()/10.0;
		label = (valueAbs/1000).toStringAsFixed(v == v.floorToDouble() ? 0 : 1) + " Thousand";
	}
	else
	{
		label = valueAbs.toStringAsFixed(0) + " Years Ago";
	}
	return "$label Years Ago";
}

class _ArticleWidgetState extends State<ArticleWidget> with SingleTickerProviderStateMixin
{
	String _articleMarkdown = "";
	String _title = "";
	String _subTitle = "";
	MarkdownStyleSheet _markdownStyleSheet;
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
			_controller.reverse(from:0.0);
		}
		else
		{
			_controller.forward(from:1.0);
		}					

		TextStyle style = new TextStyle(
			color: darkText,
			fontSize: 16.0,
			height: 1.75,
			fontFamily: "Roboto"
		);
		TextStyle strong = new TextStyle(
			color: darkText,
			fontSize: 16.0,
			height: 1.75,
			fontFamily: "RobotoMedium"
		);
		TextStyle em = new TextStyle(
			color: darkText,
			fontSize: 16.0,
			height: 1.75,
			fontFamily: "Roboto",
			fontStyle: FontStyle.italic
		);
		_markdownStyleSheet = new MarkdownStyleSheet(
			a: style,
			p: style,
			code: style,
			h1: style,
			h2: style,
			h3: style,
			h4: style,
			h5: style,
			h6: style,
			em: em,
			strong: strong,
			blockquote: style,
			img: style,
			blockSpacing: 20.0,
			listIndent: 20.0,
			blockquotePadding: 20.0,
			//blockquoteDecoration: blockquoteDecoration ?? this.blockquoteDecoration,
			//codeblockPadding: codeblockPadding ?? this.codeblockPadding,
			//codeblockDecoration: codeblockDecoration ?? this.codeblockDecoration,
			//horizontalRuleDecoration: horizontalRuleDecoration ?? this.horizontalRuleDecoration,
			);
	}

	void loadMarkdown(String filename) async
	{
		rootBundle.loadString("assets/" + filename).then((String data)
		{
			setState(() 
			{
				_articleMarkdown = data;
			});
		});
	}

	void didUpdateWidget(covariant ArticleWidget oldWidget) 
	{ 
		super.didUpdateWidget(oldWidget);
		if(oldWidget.article != widget.article)
		{
			setState(() 
			{
				print("ARTICLE ${widget.article}");
				if(widget.article == null)
				{
					_title = "N/A";
					_subTitle = "N/A";
					_articleMarkdown = "";
					return;	
				}
				_title = widget.article.label;
				_subTitle = formatYearsAgo(widget.article.start.round());
				_articleMarkdown = "";
			});
			if(widget.article.articleFilename != null)
			{
				loadMarkdown(widget.article.articleFilename);
			}
		}
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
							),
							Expanded(
								child: SingleChildScrollView
								(
									padding: EdgeInsets.only(left: 20, right:20, bottom:devicePadding.bottom),
									child: Column
									(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: <Widget>
										[
											new Container(height:280, child: ArticleVignette(isActive: widget.show, timelineEntry: widget.article)),
											Text(
												_title,
												textAlign: TextAlign.left,
												style: TextStyle(
														color: darkText,
														fontSize: 24.0,
														height: 1.3333333,
														fontFamily: "Roboto"
													)
												),
											Text(
												_subTitle,
												textAlign: TextAlign.left,
												style: TextStyle(
														color: darkText.withOpacity(darkText.opacity*0.5),
														fontSize: 16.0,
														height: 1.5,
														fontFamily: "Roboto"
													)
												),
											Container(margin:EdgeInsets.only(top:13, bottom:13), height:1, color:Colors.black.withOpacity(0.11)),
											MarkdownBody(data: _articleMarkdown, styleSheet: _markdownStyleSheet,)
										],
									)
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