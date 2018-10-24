import 'package:flutter/material.dart';
import 'package:timeline/main_menu/menu_data.dart';
import "plus_decoration.dart";
import "../colors.dart";

typedef SelectItemCallback(MenuItemData item);

class MenuSection extends StatefulWidget
{
    final String title;
    final Color backgroundColor;
    final Color accentColor;
	final SelectItemCallback selectItem;
    final List<MenuItemData> menuOptions;

    MenuSection(this.title, this.backgroundColor, this.accentColor, this.menuOptions, this.selectItem, {Key key}) : super(key: key);

    @override
    State<StatefulWidget> createState() => _SectionState();
}

class _SectionState extends State<MenuSection> with SingleTickerProviderStateMixin
{
    Animation<double> expandAnimation;
    AnimationController expandController;

	AnimationController _controller;
	static final Animatable<double> _sizeTween = Tween<double>(
		begin: 0.0,
		end: 1.0,
	).chain(CurveTween(
		curve: Curves.fastOutSlowIn,
	));

	Animation<double> _sizeAnimation;

    initState()
    {
        super.initState();

		_controller = AnimationController(
			vsync: this,
			duration: const Duration(milliseconds: 200),
		);
		_sizeAnimation = _controller.drive(_sizeTween);	
    }

    dispose()
    {
        _controller.dispose();
        expandController.dispose();
        super.dispose();
    }

    _onExpand()
    {
        switch(_sizeAnimation.status)
        {
            case AnimationStatus.completed:
                //expandController.reverse();
				_controller.reverse();
                break;
            case AnimationStatus.dismissed:
                //expandController.forward();
				_controller.forward();
                break;
            case AnimationStatus.reverse:
            case AnimationStatus.forward:
                break;
        }
    }

    @override
    Widget build(BuildContext context) {
        return GestureDetector(
            onTap: _onExpand,
            child: 
				Container(
					//height: _height,
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(10.0),
						color: widget.backgroundColor
					),
					child:  Column(
						children: 
						[
							Container(
								height: 150.0,
								child: Row(
									crossAxisAlignment: CrossAxisAlignment.end,
									children: 
									[
										Expanded(
											child: Row(
												children:
												[
													Container(
														height: 20.0,
														width: 20.0,
														margin: EdgeInsets.all(18.0),
														decoration: PlusDecoration(widget.accentColor, _sizeAnimation.value)
													),
													Text(
														widget.title,
														style: TextStyle(
															fontSize: 20.0,
															fontFamily: "RobotoMedium",
															color: widget.accentColor
														),
													)
												],
											)
										)
									]
								)
							),
							new SizeTransition(
								axisAlignment: 0.0,
								axis: Axis.vertical,
								sizeFactor: _sizeAnimation,
								child:Container(
									child: new Padding(
										padding: EdgeInsets.only(left: 56.0, right: 20.0, top: 10.0),
										child: Column
										(
											children: widget.menuOptions.map
											(
												(item) 
												{
													return GestureDetector(
														onTap: () => 
															//print("GO TO MENU OPTION: $label");
															this.widget.selectItem(item),

														child: Row(
																crossAxisAlignment: CrossAxisAlignment.start,
																children:
																[
																	Expanded(
																		child: Container(
																			margin: EdgeInsets.only(bottom: 20.0),
																			child:Text(
																				item.label, 
																				style: TextStyle(color: widget.accentColor, fontSize: 20.0, fontFamily: "RobotMedium"),
																			)
																		)
																	),
																	Container(alignment: Alignment.center,
																		child: Image.asset(
																			"assets/right_arrow.png",
																			color: widget.accentColor,
																			height: 22.0,
																			width: 22.0
																		)
																	)
																]
															)
													);
												}
											).toList()
										)
									)
								)
							)
						]
					)
				)
			);
    }
}