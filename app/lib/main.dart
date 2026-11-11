import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timeline/bloc_provider.dart';
import 'package:timeline/colors.dart';
import 'package:timeline/main_menu/main_menu.dart';
import 'package:timeline/l10n/app_localizations.dart';

/// The app is wrapped by a [BlocProvider]. This allows the child widgets
/// to access other components throughout the hierarchy without the need
/// to pass those references around.
class TimelineApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (context) =>
          AppLocalizations.of(context).text('appTitle'),
      builder: (context, child) {
        AppLocalizations strings = AppLocalizations.of(context);
        return BlocProvider(
          key: ValueKey(strings.locale.languageCode),
          localizations: strings,
          platform: Theme.of(context).platform,
          child: child,
        );
      },
      theme: ThemeData(
          backgroundColor: background, scaffoldBackgroundColor: background),
      home: MenuPage(),
    );
  }
}

class MenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: null, body: MainMenuWidget());
  }
}

void main() => runApp(TimelineApp());
