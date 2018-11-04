import 'package:flare/flare_actor.dart';
import 'package:flutter/material.dart';
import "package:flutter/services.dart" show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import "../bloc_provider.dart";
import "../colors.dart";
import '../article/timeline_entry_widget.dart';
import "../blocs/favorites_bloc.dart";
import '../timeline/timeline_entry.dart';

typedef GoBackCallback();
typedef ArticleVisibilityChanged(bool isVisible);

class ArticleWidget extends StatefulWidget {
  final GoBackCallback goBack;
  final bool show;
  final ArticleVisibilityChanged visibilityChanged;
  final TimelineEntry article;
  ArticleWidget(
      {this.goBack, this.show, this.visibilityChanged, this.article, Key key})
      : super(key: key);

  @override
  _ArticleWidgetState createState() => new _ArticleWidgetState();
}

class _ArticleWidgetState extends State<ArticleWidget>
    with SingleTickerProviderStateMixin {
  String _articleMarkdown = "";
  String _title = "";
  String _subTitle = "";
  MarkdownStyleSheet _markdownStyleSheet;
  AnimationController _controller;
  bool _isFavorite = false;

  static final Animatable<Offset> _slideTween = Tween<Offset>(
    begin: const Offset(0.0, 0.0),
    end: const Offset(1.0, 0.0),
  ).chain(CurveTween(
    curve: Curves.fastOutSlowIn,
  ));
  Animation<Offset> _articleOffset;

  initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _articleOffset = _controller.drive(_slideTween);
    if (widget.show) {
      _controller.reverse(from: 0.0);
    } else {
      _controller.forward(from: 1.0);
    }

    TextStyle style = new TextStyle(
        color: darkText, fontSize: 16.0, height: 1.75, fontFamily: "Roboto");
    TextStyle h1 = new TextStyle(
        color: darkText,
        fontSize: 32.0,
        height: 1.625,
        fontFamily: "Roboto",
        fontWeight: FontWeight.bold);
    TextStyle h2 = new TextStyle(
        color: darkText,
        fontSize: 24.0,
        height: 2,
        fontFamily: "Roboto",
        fontWeight: FontWeight.bold);
    TextStyle strong = new TextStyle(
        color: darkText,
        fontSize: 16.0,
        height: 1.75,
        fontFamily: "RobotoMedium");
    TextStyle em = new TextStyle(
        color: darkText,
        fontSize: 16.0,
        height: 1.75,
        fontFamily: "Roboto",
        fontStyle: FontStyle.italic);
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
  }

  void loadMarkdown(String filename) async {
    rootBundle.loadString("assets/Articles/" + filename).then((String data) {
      setState(() {
        _articleMarkdown = data;
      });
    });
  }

  void didUpdateWidget(covariant ArticleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.article != widget.article) {
      setState(() {
        if (widget.article == null) {
          _title = "N/A";
          _subTitle = "N/A";
          _articleMarkdown = "";
          return;
        }
        _title = widget.article.label;
        _subTitle = widget.article.formatYearsAgo();
        _articleMarkdown = "";
      });
      if (widget.article.articleFilename != null) {
        loadMarkdown(widget.article.articleFilename);
      }
    }
    if (oldWidget.show != widget.show) {
      if (widget.show) {
        _controller.reverse().whenComplete(() {
          setState(() {
            widget.visibilityChanged(true);
          });
        });
      } else {
        _controller.forward().whenComplete(() {
          setState(() {
            widget.visibilityChanged(false);
          });
        });
      }
    }
    FavoritesBloc bloc = FavoritesBloc();
    bloc.fetchFavorites().then((List<TimelineEntry> favs) {
      bool isFav = favs.any(
          (TimelineEntry te) => te.label.toLowerCase() == _title.toLowerCase());
      if (isFav != _isFavorite) {
        setState(() => _isFavorite = isFav);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    EdgeInsets devicePadding = MediaQuery.of(context).padding;
    return SlideTransition(
        position: _articleOffset,
        child: Container(
            color: background,
            child: new Stack(children: <Widget>[
              //new TimelineRenderWidget(timeline: _timeline, isActive:widget.isActive, focusItem:widget.focusItem, touchBubble:onTouchBubble),
              new Column(children: <Widget>[
                Container(height: devicePadding.top),
                Container(
                    height: 56.0,
                    width: double.infinity,
                    child: new IconButton(
                      alignment: Alignment.centerLeft,
                      icon: new Icon(Icons.arrow_back),
					  padding: EdgeInsets.only(left:20.0, right:20.0),
					  color: Colors.black.withOpacity(0.5),
                      onPressed: () {
                        this.widget.goBack();
                      },
                    )),
                Expanded(
                    child: SingleChildScrollView(
                        padding:
                            EdgeInsets.only(left: 20, right: 20, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Padding(
                                padding: EdgeInsets.only(bottom: 20),
                                child: Container(
                                    height: 280,
                                    child: TimelineEntryWidget(
                                        isActive: widget.show,
                                        timelineEntry: widget.article))),
                            Row(children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_title,
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            color: darkText,
                                            fontSize: 24.0,
                                            height: 1.3333333,
                                            fontFamily: "Roboto")),
                                    Text(_subTitle,
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            color: darkText.withOpacity(
                                                darkText.opacity * 0.5),
                                            fontSize: 16.0,
                                            height: 1.5,
                                            fontFamily: "Roboto"))
                                  ]),
                              Expanded(
                                  child:
                                      Container()), // Fill the Row with empty space
                              GestureDetector(
                                  child: Transform.translate(
                                      offset: const Offset(15.0, 0.0),
                                      child: Container(
                                        height: 48.0,
                                        width: 48.0,
                                        padding: EdgeInsets.all(15.0),
                                        color: background,
                                        child: FlareActor("assets/Favorite.flr",
                                            animation: _isFavorite
                                                ? "Favorite"
                                                : "Unfavorite",
                                            shouldClip: false),
                                      )),
                                  onTap: () {
                                    setState(() {
                                      _isFavorite = !_isFavorite;
                                    });
                                    if (_isFavorite) {
                                      BlocProvider.of(context)
                                          .addFavorite(widget.article);
                                    } else {
                                      BlocProvider.of(context)
                                          .removeFavorite(widget.article);
                                    }
                                  })
                            ]),
                            Container(
                                margin: EdgeInsets.only(top: 13, bottom: 13),
                                height: 1,
                                color: Colors.black.withOpacity(0.11)),
                            MarkdownBody(
                                data: _articleMarkdown,
                                styleSheet: _markdownStyleSheet)
                          ],
                        )))
              ])
            ])));
  }
}
