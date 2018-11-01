import 'package:flutter/material.dart';
import 'package:timeline/main_menu/menu_data.dart';
import "plus_decoration.dart";
import "package:flare/flare_actor.dart";
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
	AnimationController _controller;
	static final Animatable<double> _sizeTween = Tween<double>(
		begin: 0.0,
		end: 1.0,
	);

	Animation<double> _sizeAnimation;
	bool _isExpanded = false;

    initState()
    {
        super.initState();

		_controller = AnimationController(
			vsync: this,
			duration: const Duration(milliseconds: 200),
		);
        final CurvedAnimation curve = CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);
		_sizeAnimation = _sizeTween.animate(curve);
        _controller.addListener((){
            // print("VALUE: ${_sizeAnimation.value}");
            setState(() { /* Update so PlusDecoration can rebuild. */});
        });
    }

    dispose()
    {
        _controller.dispose();
        super.dispose();
    }

    _toggleExpand()
    {
		setState(() 
		{
			_isExpanded = !_isExpanded;
		});
        switch(_sizeAnimation.status)
        {
            case AnimationStatus.completed:
				_controller.reverse();
                break;
            case AnimationStatus.dismissed:
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
            onTap: _toggleExpand,
            child: 
				Container(
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
														child: new FlareActor("assets/Expand_Collapse.flr", color:widget.accentColor, animation: _isExpanded ? "Collapse" : "Expand")
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
																				style: TextStyle(color: widget.accentColor, fontSize: 20.0, fontFamily: "RobotoMedium"),
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