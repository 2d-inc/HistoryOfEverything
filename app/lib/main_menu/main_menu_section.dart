import 'package:flutter/material.dart';
import "plus_decoration.dart";
import "../colors.dart";

class MenuSection extends StatefulWidget
{
    final String title;
    final Color backgroundColor;
    final Color accentColor;
    final List<String> menuOptions;

    MenuSection(this.title, this.backgroundColor, this.accentColor, this.menuOptions, {Key key}) : super(key: key);

    @override
    State<StatefulWidget> createState() => _SectionState();
}

class _SectionState extends State<MenuSection> with SingleTickerProviderStateMixin
{
    Animation<double> expandAnimation;
    AnimationController expandController;
    double _height = 150.0;

    initState()
    {
        super.initState();
        expandController = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 350)
        );
        expandAnimation = Tween(begin: 0.0, end: 1.0).animate(expandController)
                        ..addListener(
                            ()
                            {
                                setState(()
                                    {
                                        _height = 150.0 + (350.0-150.0)*expandAnimation.value;
                                    }
                                );
                            });
    }

    dispose()
    {
        expandController.dispose();
        super.dispose();
    }

    _onExpand()
    {
        switch(expandAnimation.status)
        {
            case AnimationStatus.completed:
                expandController.reverse();
                break;
            case AnimationStatus.dismissed:
                expandController.forward();
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
            child: Container(
                height: _height,
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
                                                    decoration: PlusDecoration(widget.accentColor, expandAnimation.value)
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
                        Container(
                            height: _height-150.0,
                            child: ListView(
                                padding: EdgeInsets.only(left: 56.0, right: 20.0, top: 10.0),
                                children: widget.menuOptions.map(
                                    (label) {
                                        return GestureDetector(
                                            onTap: () => print("GO TO MENU OPTION: $label"),
                                            child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children:
                                                    [
                                                        Expanded(
                                                            child: Container(
                                                                margin: EdgeInsets.only(bottom: 20.0),
                                                                child:Text(
                                                                    label, 
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
                    ]
                )
            )
        );
    }
}