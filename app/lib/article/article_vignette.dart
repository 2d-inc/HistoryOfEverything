import 'package:flare/flare_actor.dart';
import 'package:flutter/material.dart';
import "package:flutter/services.dart" show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:timeline/timeline/timeline_entry.dart';

import "../bloc_provider.dart";
import "../colors.dart";
import '../article/timeline_entry_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ArticleVignette extends StatefulWidget  
{
	final TimelineEntry article;
	final Offset interactOffset;
	ArticleVignette({this.article, this.interactOffset, Key key}) : super(key: key);

  @override
  _ArticleVignetteState createState() => new _ArticleVignetteState();
}

class _ArticleVignetteState extends State<ArticleVignette>
{
	initState() {
    	super.initState();
	}
	@override
    Widget build(BuildContext context) 
	{
		return TimelineEntryWidget(isActive: true, timelineEntry: widget.article, interactOffset: widget.interactOffset);
	}
}