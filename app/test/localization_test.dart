import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeline/blocs/favorites_bloc.dart';
import 'package:timeline/l10n/app_localizations.dart';
import 'package:timeline/main_menu/menu_data.dart';
import 'package:timeline/main_menu/search_widget.dart';
import 'package:timeline/search_manager.dart';
import 'package:timeline/timeline/timeline_entry.dart';
import 'package:timeline/timeline/timeline.dart';

class ArticleBundle extends CachingAssetBundle {
  final Map<String, String> articles;
  ArticleBundle(this.articles);

  @override
  Future<ByteData> load(String key) async {
    if (!articles.containsKey(key)) throw FlutterError('Missing asset: $key');
    return ByteData.view(Uint8List.fromList(utf8.encode(articles[key])).buffer);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppLocalizations> chinese() =>
      AppLocalizations.delegate.load(const Locale('zh', 'CN'));

  test('Chinese catalog covers all interface strings and source labels',
      () async {
    Map catalog =
        json.decode(await rootBundle.loadString('assets/l10n/zh.json'));
    expect((catalog['strings'] as Map).keys.toSet(),
        AppLocalizations.english.keys.toSet());
    for (String key in AppLocalizations.english.keys) {
      String translated = catalog['strings'][key];
      expect(translated.trim(), isNotEmpty, reason: key);
      final placeholders = RegExp(r'\{\w+\}');
      expect(
          placeholders.allMatches(translated).map((m) => m.group(0)).toSet(),
          placeholders
              .allMatches(AppLocalizations.english[key])
              .map((m) => m.group(0))
              .toSet(),
          reason: key);
    }

    List timeline =
        json.decode(await rootBundle.loadString('assets/timeline.json'));
    List menu = json.decode(await rootBundle.loadString('assets/menu.json'));
    Set<String> labels = Set.from(timeline.map((entry) => entry['label']));
    for (Map section in menu) {
      labels.add(section['label']);
      for (Map item in section['items']) labels.add(item['label']);
    }
    expect((catalog['labels'] as Map).keys.toSet(), labels);
    for (String label in labels) {
      expect(catalog['labels'][label], matches(RegExp(r'[\u4e00-\u9fff]')),
          reason: label);
    }
  });

  test('every bundled English article has a nonempty Chinese counterpart',
      () async {
    AppLocalizations strings = await chinese();
    Map manifest =
        json.decode(await rootBundle.loadString('AssetManifest.json'));
    Set<String> originals = manifest.keys
        .cast<String>()
        .where((path) => RegExp(r'^assets/Articles/[^/]+\.txt$').hasMatch(path))
        .map((path) => path.split('/').last)
        .toSet();
    Set<String> translations = manifest.keys
        .cast<String>()
        .where((path) =>
            path.startsWith('assets/Articles/zh/') && path.endsWith('.txt'))
        .map((path) => path.split('/').last)
        .toSet();
    expect(originals, hasLength(45));
    expect(translations, originals);
    List timeline =
        json.decode(await rootBundle.loadString('assets/timeline.json'));
    expect(originals, containsAll(timeline.map((entry) => entry['article'])));
    for (String filename in originals) {
      String text = await strings.loadArticle(filename);
      expect(text, matches(RegExp(r'[\u4e00-\u9fff]')), reason: filename);
      expect(text, isNot(await const AppLocalizations().loadArticle(filename)));
    }
  });

  test('missing translations fall back to English', () async {
    AppLocalizations partial = const AppLocalizations(Locale('zh'));
    expect(partial.text('search'), 'Search');
    expect(partial.label('Untranslated event'), 'Untranslated event');
    final bundle =
        ArticleBundle({'assets/Articles/future.txt': 'English article'});
    expect(await partial.loadArticle('future.txt', bundle: bundle),
        'English article');
    final translated = ArticleBundle({
      'assets/Articles/future.txt': 'English article',
      'assets/Articles/zh/future.txt': '中文文章',
    });
    expect(await partial.loadArticle('future.txt', bundle: translated), '中文文章');
    expect(
        await const AppLocalizations()
            .loadArticle('future.txt', bundle: translated),
        'English article');
  });

  test('menu localization preserves navigation and animation data', () async {
    MenuData english = MenuData();
    MenuData translated = MenuData();
    await english.loadFromBundle('assets/menu.json');
    await translated.loadFromBundle('assets/menu.json', await chinese());
    expect(translated.sections.first.label, '宇宙诞生');
    expect(translated.sections.first.items.first.label, '宇宙大爆炸');
    for (int s = 0; s < english.sections.length; s++) {
      final original = english.sections[s];
      final localized = translated.sections[s];
      expect(localized.assetId, original.assetId);
      expect(localized.backgroundColor, original.backgroundColor);
      expect(localized.textColor, original.textColor);
      for (int i = 0; i < original.items.length; i++) {
        expect(localized.items[i].start, original.items[i].start);
        expect(localized.items[i].end, original.items[i].end);
      }
    }
  });

  test('timeline loads translated labels without changing source data',
      () async {
    AppLocalizations strings = await chinese();
    Timeline timeline = Timeline(TargetPlatform.android, strings);
    List<TimelineEntry> entries =
        await timeline.loadFromBundle('assets/timeline.json');
    List source =
        json.decode(await rootBundle.loadString('assets/timeline.json'));
    expect(entries, hasLength(source.length));
    Map<String, TimelineEntry> byArticle = Map.fromIterable(entries,
        key: (entry) => entry.articleFilename, value: (entry) => entry);
    for (Map original in source) {
      TimelineEntry entry = byArticle[original['article']];
      expect(entry.sourceLabel, original['label']);
      expect(entry.label, strings.label(original['label']));
      expect(entry.start, original['date'] ?? original['start']);
      expect(entry.id, original['id']);
      expect(entry.favoriteId, original['article']);
      expect(entry.lineCount, entry.label.split('\n').length);
    }
  });

  test('Chinese dates and relative navigation use local units', () async {
    AppLocalizations strings = await chinese();
    expect(TimelineEntry.formatYears(-13800000000.0, strings), '138亿年');
    expect(TimelineEntry.formatYears(-100000000.0, strings), '1亿年');
    expect(TimelineEntry.formatYears(-3800000.0, strings), '380万年');
    expect(TimelineEntry.formatYears(-10000.0, strings), '1万年');
    expect(TimelineEntry.formatYears(-9999.0, strings), '9999年');
    expect(TimelineEntry.formatYears(-13800000000.0), '13.8 Billion Years');
    final entry = TimelineEntry()
      ..localizations = strings
      ..start = -13800000000.0;
    expect(entry.formatYearsAgo(), '138亿年前');
    entry.start = 1969.0;
    expect(entry.formatYearsAgo(), '1969年');
    entry.localizations = const AppLocalizations();
    expect(entry.formatYearsAgo(), '1969');
    expect(strings.interpolate('nextEvent', {'years': '1万年', 'pages': '2'}),
        '1万年后\n（约滚动 2 屏）');
    expect(strings.interpolate('previousEvent', {'years': '1万年', 'pages': '2'}),
        '1万年前\n（约滚动 2 屏）');
    expect(
        NumberFormat.compact(locale: strings.numberLocale).format(10000), '1万');
  });

  test('search accepts Chinese and case-insensitive English aliases', () async {
    AppLocalizations strings = await chinese();
    final entry = TimelineEntry()
      ..sourceLabel = 'Big Bang'
      ..label = strings.label('Big Bang');
    SearchManager manager = SearchManager.init([entry]);
    expect(manager.performSearch('大爆炸'), contains(entry));
    expect(manager.performSearch(' BANG '), contains(entry));
    expect(manager.performSearch(''), [entry].toSet());
    expect(manager.performSearch('missing'), isEmpty);
    final english = TimelineEntry()..label = 'Moon Landing';
    SearchManager.init([english]);
    expect(manager.performSearch('大爆炸'), isEmpty);
    expect(manager.performSearch('MOON'), [english].toSet());
  });

  test('legacy favorites migrate and survive a change of language', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.${FavoritesBloc.FAVORITES_KEY}': [
        'Moon Landing',
        'Big Bang',
        'big_bang.txt'
      ],
    });
    AppLocalizations strings = await chinese();
    final bang = TimelineEntry()
      ..sourceLabel = 'Big Bang'
      ..label = strings.label('Big Bang')
      ..articleFilename = 'big_bang.txt'
      ..start = -13800000000.0;
    final moon = TimelineEntry()
      ..sourceLabel = 'Moon Landing'
      ..label = strings.label('Moon Landing')
      ..articleFilename = 'moon_landing.txt'
      ..start = 1969.0;
    FavoritesBloc favorites = FavoritesBloc();
    await favorites.init([moon, bang]);
    expect(favorites.favorites, [bang, moon]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(FavoritesBloc.FAVORITES_KEY),
        ['big_bang.txt', 'moon_landing.txt']);
    bang.label = bang.sourceLabel;
    moon.label = moon.sourceLabel;
    await favorites.init([moon, bang]);
    expect(favorites.favorites, [bang, moon]);
    favorites.removeFavorite(bang);
    await Future<void>.delayed(Duration.zero);
    expect(
        prefs.getStringList(FavoritesBloc.FAVORITES_KEY), ['moon_landing.txt']);
    favorites.addFavorite(bang);
    await Future<void>.delayed(Duration.zero);
    expect(prefs.getStringList(FavoritesBloc.FAVORITES_KEY),
        ['big_bang.txt', 'moon_landing.txt']);
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh', 'CN'),
    const Locale('zh', 'TW'),
    const Locale('fr')
  ]) {
    testWidgets('search field resolves device locale $locale', (tester) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate
        ],
        home: Scaffold(body: SearchWidget(focus, controller)),
      ));
      await tester.pumpAndSettle();
      expect(
          tester.widget<TextField>(find.byType(TextField)).decoration.hintText,
          locale.languageCode == 'zh' ? '搜索' : 'Search');
      expect(find.text(locale.languageCode == 'zh' ? '搜索' : 'Search'),
          findsOneWidget);
      await tester.enterText(find.byType(TextField), '宇宙');
      expect(controller.text, '宇宙');
      await tester.pumpWidget(Container());
      controller.dispose();
      focus.dispose();
    });
  }
}
