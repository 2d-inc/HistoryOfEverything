import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// English is the source language. Translation catalogs only override text;
/// dates, animation identifiers and article filenames remain language independent.
class AppLocalizations {
  final Locale locale;
  final Map<String, dynamic> _catalog;

  const AppLocalizations(
      [this.locale = const Locale('en'),
      this._catalog = const <String, dynamic>{}]);

  static const delegate = AppLocalizationsDelegate();
  static const supportedLocales = <Locale>[Locale('en'), Locale('zh')];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

  bool get isChinese => locale.languageCode == 'zh';
  String get numberLocale => isChinese ? 'zh' : 'en';

  static const Map<String, String> english = {
    'appTitle': 'The History of Everything',
    'aboutTitle': 'The History of\nEverything',
    'search': 'Search',
    'favorites': 'Your Favorites',
    'share': 'Share',
    'about': 'About',
    'shareMessage': 'Check out The History of Everything! ',
    'emptyFavorites': 'You haven’t favorited anything yet.',
    'favoritesHint':
        'Browse to an event in the timeline and tap on the heart icon to save something in this list.',
    'builtWithIntro': 'The History of Everything is built with ',
    'builtBy': ' by ',
    'graphicsCredit':
        '. The graphics and animations were created using tools by ',
    'inspiration': '.\n\nInspired by the Kurzgesagt video ',
    'videoTitle': 'The History & Future of Everything',
    'sentenceEnd': '.',
    'designedBy': 'Designed by',
    'builtWith': 'Built with',
    'yearsAgo': '{years} Ago',
    'nextEvent': 'in {years}\n({pages} page scrolls)',
    'previousEvent': '{years} ago\n({pages} page scrolls)',
  };

  String text(String key) {
    Map translations = _catalog['strings'];
    return (translations == null ? null : translations[key]) ??
        english[key] ??
        key;
  }

  String label(String source) {
    Map translations = _catalog['labels'];
    return (translations == null ? null : translations[source]) ?? source;
  }

  String interpolate(String key, Map<String, String> values) {
    String result = text(key);
    values.forEach((String name, String value) {
      result = result.replaceAll('{$name}', value);
    });
    return result;
  }

  /// Try a localized article first; incomplete future translations fall back to
  /// the original article. The caller may pass a bundle for testing.
  Future<String> loadArticle(String filename, {AssetBundle bundle}) async {
    bundle ??= rootBundle;
    if (isChinese) {
      try {
        return await bundle.loadString('assets/Articles/zh/$filename');
      } on FlutterError {
        // The English article is always bundled.
      }
    }
    return bundle.loadString('assets/Articles/$filename');
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    if (locale.languageCode != 'zh') {
      return SynchronousFuture<AppLocalizations>(const AppLocalizations());
    }
    return rootBundle
        .loadStructuredData<Map<String, dynamic>>(
          'assets/l10n/zh.json',
          (String data) => SynchronousFuture<Map<String, dynamic>>(
              json.decode(data) as Map<String, dynamic>),
        )
        .then((catalog) => AppLocalizations(locale, catalog));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
