import "package:flutter/material.dart";
import 'package:flutter/services.dart';

import "package:timeline/bloc_provider.dart";
import 'package:timeline/colors.dart';
import "package:timeline/main_menu/main_menu.dart";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return BlocProvider(
            child: MaterialApp(
                title: 'History & Future of Everything',
                theme: new ThemeData(
                    backgroundColor: background,
                    scaffoldBackgroundColor: background
                ),
                home: MenuPage(),
            ),
            platform: Theme.of(context).platform,
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