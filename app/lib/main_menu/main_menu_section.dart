import 'package:flutter/material.dart';
import 'package:timeline/bloc_provider.dart';
import 'package:timeline/main_menu/menu_data.dart';
import "package:flare/flare_actor.dart" as flare;
import 'package:timeline/main_menu/menu_vignette.dart';
import 'package:timeline/timeline/timeline_widget.dart';
typedef SelectItemCallback(MenuItemData item);

class MenuSection extends StatefulWidget
{
    final String title;
    final Color backgroundColor;
    final Color accentColor;
    final List<MenuItemData> menuOptions;
	final String assetId;
	// final SelectItemCallback selectItem;
	// final Timeline timeline;
	// final bool isActive;

    MenuSection(this.title, this.backgroundColor, this.accentColor, this.menuOptions, {this.assetId, Key key}) : super(key: key);

  get isActive => null;

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
            // print("VALUE: ${_sizeAnimation.status}");
            setState(() { });
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
        bool isMenuSectionActive = _sizeAnimation.status == AnimationStatus.forward || _sizeAnimation.status == AnimationStatus.completed;

        return GestureDetector(
            onTap: _toggleExpand,
            child: 
				Container(
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(10.0),
						color: widget.backgroundColor
					),
					child:  new ClipRRect(borderRadius: BorderRadius.circular(10.0), child:
						new Stack(children: <Widget>
						[
							new Positioned.fill(left:0, top:0, child:new MenuVignette(gradientColor:widget.backgroundColor, isActive: isMenuSectionActive, assetId:widget.assetId)),
							Column(children: <Widget>
							[
								Container
								(
									height: 150.0,
									alignment: Alignment.bottomCenter,
									child: Row(
										crossAxisAlignment: CrossAxisAlignment.center,
												children:
												[
													Container(
														height: 21.0,
														width: 21.0,
														margin: EdgeInsets.all(18.0),
														child: new flare.FlareActor("assets/ExpandCollapse.flr", color:widget.accentColor, animation: _isExpanded ? "Collapse" : "Expand")
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
										
								),
								SizeTransition(
									axisAlignment: 0.0,
									axis: Axis.vertical,
									sizeFactor: _sizeAnimation,
									child:Container(
										child: Padding(
											padding: EdgeInsets.only(left: 56.0, right: 20.0, top: 10.0),
											child: Column
											(
												children: widget.menuOptions.map
												(
													(item) 
													{
														return GestureDetector(
                                                            onTap: () {
                                                                Navigator.of(context).push(
                                                                    PageRouteBuilder(
                                                                        opaque: true,
                                                                        transitionDuration: const Duration(milliseconds: 300),
                                                                        pageBuilder: (context, _, __) => TimelineWidget(item, BlocProvider.getTimeline(context)),
                                                                        transitionsBuilder: (_, Animation<double> animation, __, Widget child)
                                                                        {
                                                                            return SlideTransition(
                                                                                child: child,
                                                                                position: Tween<Offset>(
                                                                                    begin: const Offset(1.0, 0.0),
                                                                                    end: Offset.zero
                                                                                ).animate(CurvedAnimation(
                                                                                    parent: animation,
                                                                                    curve: Curves.fastOutSlowIn
                                                                                ))
                                                                            );
                                                                        }
                                                                    )
                                                                );
                                                            },
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
						),
				],
			)
		)
	));
    }
}

class NimaDecoration extends Decoration
{
    final Color color;
    final double expandValue;

    NimaDecoration(this.color, this.expandValue);

    @override
    BoxPainter createBoxPainter([VoidCallback onChanged])
    {
        return NimaPainter(color, expandValue);
    }
}

class NimaPainter extends BoxPainter
{
    final Color color;
    final double expandValue;

    NimaPainter(this.color, this.expandValue);

    @override
    void paint(Canvas canvas, Offset offset, ImageConfiguration config)
    {
        canvas.save();

        canvas.restore();
    }
}