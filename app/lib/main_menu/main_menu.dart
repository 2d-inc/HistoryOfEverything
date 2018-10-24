import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:timeline/main_menu/menu_data.dart';

import "./search_widget.dart";
import "./main_menu_section.dart";
import "../colors.dart";
typedef VisibilityChanged(bool isVisible);


class MainMenuWidget extends StatefulWidget  
{
	final SelectItemCallback selectItem;
	final MenuData data;
	final bool show;
	final VisibilityChanged visibilityChanged;
	MainMenuWidget({this.selectItem, this.data, this.show, this.visibilityChanged, Key key}) : super(key: key);

	@override
	 _MainMenuWidgetState createState() => new _MainMenuWidgetState();
}

class _MainMenuWidgetState extends State<MainMenuWidget> with SingleTickerProviderStateMixin
{
	AnimationController _controller;
	static final Animatable<Offset> _slideTween = Tween<Offset>(
		begin: const Offset(0.0, 0.0),
		end: const Offset(-1.0, 0.0),
	).chain(CurveTween(
		curve: Curves.fastOutSlowIn,
	));
	Animation<Offset> _menuOffset;

	initState()
	{
		super.initState();

		_controller = AnimationController(
			vsync: this,
			duration: const Duration(milliseconds: 200),
		);
		_menuOffset = _controller.drive(_slideTween);		
		if(widget.show)
		{
			_controller.reverse();
		}
		else
		{
			_controller.forward();
		}									
	}

	void didUpdateWidget(covariant MainMenuWidget oldWidget) 
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
			position: _menuOffset, 
			child: new Container(
				color: background,
				child: Container(
					margin: EdgeInsets.only(top:devicePadding.top, left: 20.0, right: 20.0),
					child: SingleChildScrollView(
						child: new Padding(
							padding: EdgeInsets.only(top: 35.0, left:devicePadding.left, right:devicePadding.right, bottom:devicePadding.bottom),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: 
								[
									Row(
										children:
										[
											Image.asset(
												"assets/flutter_logo.png",
												color: Colors.black.withOpacity(0.62),
												height: 22.0,
												width: 22.0
											),
											Container(
												margin: EdgeInsets.only(left: 10.0),
												child: Text(
													"Flutter Presents",
													style: TextStyle(
														color: darkText.withOpacity(darkText.opacity*0.75),
														fontSize: 16.0,
														fontFamily: "Roboto"
														)
												)
											)
										]),
										Container(
											// color: Color.fromRGBO(0, 0, 0, 1.0),
											margin: EdgeInsets.only(top: 14.0, bottom: 22.0),
											child: Text(
												"The History & Future\nof Everything",
												textAlign: TextAlign.left,
												style: TextStyle(
														color: darkText.withOpacity(darkText.opacity*0.75),
														fontSize: 34.0,
														fontFamily: "RobotoMedium"
													)
												)
										),
										SearchWidget()
									]..addAll(
										widget.data.sections.map((MenuSectionData section) => 
											Container(
												margin: EdgeInsets.only(top: 20.0),
												child: MenuSection(
													section.label, 
													section.backgroundColor,
													section.textColor,
													section.items,
													widget.selectItem
												)
											)
										)
									)
								)
						)
					)
				)
			)
		);
    }

}