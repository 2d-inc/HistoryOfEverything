import 'package:flare/flare_actor.dart';
import 'package:flutter/material.dart';
import "package:flutter/services.dart" show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:timeline/article/article_vignette.dart';

import "../bloc_provider.dart";
import "../colors.dart";
import '../article/timeline_entry_widget.dart';
import '../timeline/timeline_entry.dart';

typedef GoBackCallback();
typedef ArticleVisibilityChanged(bool isVisible);

class ArticleWidget extends StatefulWidget  
{
	final TimelineEntry article;
	ArticleWidget({this.article, Key key}) : super(key: key);

  @override
  _ArticleWidgetState createState() => new _ArticleWidgetState();
}

class _ArticleWidgetState extends State<ArticleWidget>
    with SingleTickerProviderStateMixin {
  String _articleMarkdown = "";
  String _title = "";
  String _subTitle = "";
  MarkdownStyleSheet _markdownStyleSheet;
  bool _isFavorite = false;

  Offset _interactOffset;

  initState() {
    super.initState();

		TextStyle style = new TextStyle(
			color: darkText.withOpacity(darkText.opacity*0.68),
			fontSize: 17.0,
			height: 1.5,
			fontFamily: "Roboto"
		);
		TextStyle h1 = new TextStyle(
			color: darkText.withOpacity(darkText.opacity*0.68),
			fontSize: 32.0,
			height: 1.625,
			fontFamily: "Roboto",
            fontWeight: FontWeight.bold
		);
		TextStyle h2 = new TextStyle(
			color: darkText.withOpacity(darkText.opacity*0.68),
			fontSize: 24.0,
			height: 2,
			fontFamily: "Roboto",
            fontWeight: FontWeight.bold
		);
		TextStyle strong = new TextStyle(
			color: darkText.withOpacity(darkText.opacity*0.68),
			fontSize: 17.0,
			height: 1.5,
			fontFamily: "RobotoMedium"
		);
		TextStyle em = new TextStyle(
			color: darkText.withOpacity(darkText.opacity*0.68),
			fontSize: 17.0,
			height: 1.5,
			fontFamily: "Roboto",
			fontStyle: FontStyle.italic
		);
		_markdownStyleSheet = new MarkdownStyleSheet(
			a: style,
			p: style,
			code: style,
			h1: h1,
			h2: h2,
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
        setState((){
            _title = widget.article.label;
            _subTitle = widget.article.formatYearsAgo();
            _articleMarkdown = "";
            if(widget.article.articleFilename != null)
            {
                loadMarkdown(widget.article.articleFilename);
            }
        });
	}

	void loadMarkdown(String filename) async
	{
		rootBundle.loadString("assets/Articles/" + filename).then((String data)
		{
			setState(() 
			{
				_articleMarkdown = data;
			});
		});
	}

    @override
    Widget build(BuildContext context) 
	{
		EdgeInsets devicePadding = MediaQuery.of(context).padding;
        List<TimelineEntry> favs = BlocProvider.favorites(context).favorites;
        bool isFav = favs.any((TimelineEntry te) => te.label.toLowerCase() == _title.toLowerCase());
		TimelineAsset asset = widget.article?.asset;
		bool hasMap = asset is TimelineFlare && asset.mapNode != null;
		return Scaffold(
			body:Container(
				color: Color.fromRGBO(255, 255, 255, 1),
				child: new Stack(
					children:<Widget>
					[
						new Column(
						children: <Widget>[
							Container(
								height:devicePadding.top
							),
							Container(
								height: 56.0,
								width: double.infinity,
								child: new IconButton(
									alignment: Alignment.centerLeft,
									icon: new Icon(Icons.arrow_back),
                                    padding: EdgeInsets.only(left:20.0, right:20.0),
					                color: Colors.black.withOpacity(0.5),
									onPressed: () {
                                            Navigator.pop(context, true);
                                        },
								)
							),
							Expanded(
								child: SingleChildScrollView
								(
									physics: hasMap ? new NeverScrollableScrollPhysics() : null,
									padding: EdgeInsets.only(left: 20, right:20, bottom: 30),
									child: Column
									(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: <Widget>
										[
											GestureDetector(
												onPanStart: hasMap ? null : (DragStartDetails details)
												{
													setState(()
													{
														_interactOffset = details.globalPosition;
													});
												},
												onPanUpdate: hasMap ? null : (DragUpdateDetails details)
												{
													setState(()
													{
														_interactOffset = details.globalPosition;
													});
												},
												onPanEnd: hasMap ? null : (DragEndDetails details)
												{
													setState(()
													{
														_interactOffset = null;
													});
												},
												onTapDown: hasMap ? (TapDownDetails details)
												{
													setState(()
													{
														_interactOffset = details.globalPosition;
													});
												} : null,
												onTapUp: hasMap ? (TapUpDetails details)
												{
													setState(()
													{
														_interactOffset = null;
													});
												} : null,
												child:new Container(
                                                	height:280,
                                                	child:ArticleVignette(article: widget.article, interactOffset: _interactOffset)
												)
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(top:30.0),
                                              child: Row(
                                                  children:
                                                  [
                                                      Expanded(
                                                          child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children:
                                                              [
                                                                  Text(
                                                                      _title,
                                                                      textAlign: TextAlign.left,
                                                                      style: TextStyle(
                                                                              color: darkText.withOpacity(darkText.opacity*0.87),
                                                                              fontSize: 25.0,
                                                                              height: 1.1,
                                                                              fontFamily: "Roboto",
                                                                          )
                                                                      ),
                                                                  Text(
                                                                      _subTitle,
                                                                      textAlign: TextAlign.left,
                                                                      style: TextStyle(
                                                                              color: darkText.withOpacity(darkText.opacity*0.5),
                                                                              fontSize: 17.0,
                                                                              height: 1.5,
                                                                              fontFamily: "Roboto"
                                                                          )
                                                                      )
                                                              ]
                                                          ),
                                                      ),
                                                      GestureDetector(
                                                        child: Transform.translate(offset: const Offset(15.0, 0.0), child:Container(
                                                          height: 60.0,
                                                          width: 60.0,
                                                          padding: EdgeInsets.all(15.0),
                                                          color: Colors.white,
                                                          child: FlareActor("assets/Favorite.flr", animation: isFav ? "Favorite" : "Unfavorite", shouldClip: false),
                                                        )),
                                                        onTap:()
                                                        {
                                                          setState(() {
                                                              _isFavorite = !_isFavorite;
                                                            });
                                                            if(_isFavorite)
                                                            {
                                                              BlocProvider.favorites(context).addFavorite(widget.article);
                                                            }
                                                            else
                                                            {
                                                              BlocProvider.favorites(context).removeFavorite(widget.article);
                                                            }
                                                        }
                                                      )
                                                      
                                                  ]
                                              ),
                                            ),
											Container(margin:EdgeInsets.only(top:20, bottom:20), height:1, color:Colors.black.withOpacity(0.11)),
                                            MarkdownBody(data: _articleMarkdown, styleSheet: _markdownStyleSheet),
											SizedBox(height: 100),
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
