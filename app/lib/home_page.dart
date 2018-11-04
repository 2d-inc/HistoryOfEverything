import "package:flutter/material.dart";

import "package:timeline/bloc_provider.dart";
import 'package:timeline/colors.dart';
import "package:timeline/main_menu/main_menu.dart";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
            child: MaterialApp(
                title: 'History & Future of Everything',
                theme: new ThemeData(
                    primarySwatch: Colors.blue,
                    backgroundColor: background
                ),
                home: MenuPage()
        )
    );
  }
}

class MenuPage extends StatelessWidget
{
    @override
    Widget build(BuildContext context)
    {
        return Scaffold(
            appBar: null,
            body: MainMenuWidget()
        );
    }
}