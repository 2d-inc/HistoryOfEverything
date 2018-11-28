import 'dart:async';
import 'dart:collection';
import "dart:convert";
import "dart:math";
import "dart:typed_data";
import "dart:ui" as ui;

import 'package:flutter/material.dart';
import "package:flutter/scheduler.dart";
import "package:flutter/services.dart" show rootBundle;
import 'package:flutter/widgets.dart';
import "package:nima/nima.dart" as nima;
import "package:nima/nima/actor_image.dart" as nima;
import "package:nima/nima/animation/actor_animation.dart" as nima;
import "package:nima/nima/math/aabb.dart" as nima;
import "package:nima/nima/math/vec2d.dart" as nima;
import "package:flare/flare.dart" as flare;
import "package:flare/flare/animation/actor_animation.dart" as flare;
import "package:flare/flare/math/aabb.dart" as flare;
import "package:flare/flare/math/vec2d.dart" as flare;
import 'package:video_player/video_player.dart';
import "timeline_entry.dart";

typedef PaintCallback();
typedef ChangeEraCallback(TimelineEntry era);
typedef ChangeHeaderColorCallback(Color background, Color text);

const String videoStreamUrl =
    'http://mirrors.standaloneinstaller.com/video-sample/grb_2.mp4';

Color interpolateColor(Color from, Color to, double elapsed) {
  double r, g, b, a;
  double speed = min(1.0, elapsed * 5.0);
  double c = to.alpha.toDouble() - from.alpha.toDouble();
  if (c.abs() < 1.0) {
    a = to.alpha.toDouble();
  } else {
    a = from.alpha + c * speed;
  }

  c = to.red.toDouble() - from.red.toDouble();
  if (c.abs() < 1.0) {
    r = to.red.toDouble();
  } else {
    r = from.red + c * speed;
  }

  c = to.green.toDouble() - from.green.toDouble();
  if (c.abs() < 1.0) {
    g = to.green.toDouble();
  } else {
    g = from.green + c * speed;
  }

  c = to.blue.toDouble() - from.blue.toDouble();
  if (c.abs() < 1.0) {
    b = to.blue.toDouble();
  } else {
    b = from.blue + c * speed;
  }

  return Color.fromARGB(a.round(), r.round(), g.round(), b.round());
}

String getExtension(String filename) {
  int dot = filename.lastIndexOf(".");
  if (dot == -1) {
    return null;
  }
  return filename.substring(dot + 1);
}

String removeExtension(String filename) {
  int dot = filename.lastIndexOf(".");
  if (dot == -1) {
    return null;
  }
  return filename.substring(0, dot);
}

class TimelineBackgroundColor {
  Color color;
  double start;
}

class TickColors {
  Color background;
  Color long;
  Color short;
  Color text;
  double start;
  double screenY;
}

class HeaderColors {
  Color background;
  Color text;
  double start;
  double screenY;
}

class Heart extends LinkedListEntry<Heart> {
  double start, end;
  double x;
  double elapsed;
  double phase;
  double opacity;

  int layer;

  double duration;
}

class Timeline {
  double _start = 0.0;
  double _end = 0.0;
  double _renderStart;
  double _renderEnd;
  double _lastFrameTime = 0.0;
  double _height = 0.0;
  double _width = 0.0;
  double get width => _width;
  double get height => _height;
  bool _showFavorites = false;
  LinkedList<Heart> hearts = LinkedList<Heart>();
  bool addHearts = false;
  List<TimelineBackgroundColor> _backgroundColors;
  List<TickColors> _tickColors;
  List<HeaderColors> _headerColors;
  HeaderColors _currentHeaderColors;
  Color _headerTextColor;
  Color _headerBackgroundColor;
  List<TimelineEntry> _entries;
  Map<String, TimelineEntry> _entriesById = Map<String, TimelineEntry>();
  List<TimelineAsset> _renderAssets;
  double _firstOnScreenEntryY = 0.0;
  double _lastEntryY = 0.0;
  double _lastOnScreenEntryY = 0.0;
  double _offsetDepth = 0.0;
  double _renderOffsetDepth = 0.0;
  double _labelX = 0.0;
  double _renderLabelX = 0.0;
  bool _isFrameScheduled = false;
  bool _isInteracting = false;
  double _lastAssetY = 0.0;
  bool _isActive = false;
  TimelineEntry _currentEra;
  TimelineEntry _lastEra;

  TimelineEntry _nextEntry;
  TimelineEntry _renderNextEntry;
  double _nextEntryOpacity = 0.0;
  double _distanceToNextEntry = 0.0;

  TimelineEntry _prevEntry;
  TimelineEntry _renderPrevEntry;
  double _prevEntryOpacity = 0.0;
  double _distanceToPrevEntry = 0.0;

  TimelineEntry watchPartyEntry;

  TimelineEntry get currentEra => _currentEra;

  List<TimelineEntry> get entries => _entries;
  List<TimelineBackgroundColor> get backgroundColors => _backgroundColors;
  List<TickColors> get tickColors => _tickColors;
  HeaderColors get currentHeaderColors => _currentHeaderColors;
  Color get headerTextColor => _headerTextColor;
  Color get headerBackgroundColor => _headerBackgroundColor;
  double get renderOffsetDepth => _renderOffsetDepth;
  double get renderLabelX => _renderLabelX;
  List<TimelineAsset> get renderAssets => _renderAssets;
  Map<String, nima.FlutterActor> _nimaResources =
      Map<String, nima.FlutterActor>();
  Map<String, flare.FlutterActor> _flareResources =
      Map<String, flare.FlutterActor>();

  PaintCallback onNeedPaint;
  ChangeEraCallback onEraChanged;
  ChangeHeaderColorCallback onHeaderColorsChanged;
  Timer _steadyTimer;
  double get start => _start;
  double get end => _end;
  double get renderStart => _renderStart;
  double get renderEnd => _renderEnd;
  bool get isInteracting => _isInteracting;
  bool get showFavorites => _showFavorites;
  set showFavorites(bool value) {
    if (_showFavorites != value) {
      _showFavorites = value;
      startRendering();
    }
  }

  bool _isScaling = false;
  set isInteracting(bool value) {
    if (value != _isInteracting) {
      _isInteracting = value;
      updateSteady();
    }
  }

  set isScaling(bool value) {
    if (value != _isScaling) {
      _isScaling = value;
      updateSteady();
    }
  }

  get isActive => _isActive;
  set isActive(bool isIt) {
    if (isIt != _isActive) {
      _isActive = isIt;
      if (_isActive) {
        startRendering();
      }
    }
  }

  bool _isSteady = false;

  void updateSteady() {
    bool isIt = !_isInteracting && !_isScaling;

    if (_steadyTimer != null) {
      _steadyTimer.cancel();
      _steadyTimer = null;
    }

    if (isIt) {
      _steadyTimer = Timer(Duration(milliseconds: SteadyMilliseconds), () {
        _steadyTimer = null;
        _isSteady = true;
        startRendering();
      });
    } else {
      _isSteady = false;
      startRendering();
    }
  }

  void startRendering() {
    if (!_isFrameScheduled) {
      _isFrameScheduled = true;
      _lastFrameTime = 0.0;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    }
  }

  static const double LineWidth = 2.0;
  static const double LineSpacing = 10.0;
  static const double DepthOffset = LineSpacing + LineWidth;

  static const double EdgePadding = 8.0;
  static const double MoveSpeed = 10.0;
  static const double MoveSpeedInteracting = 40.0;
  static const double Deceleration = 3.0;
  static const double GutterLeft = 45.0;
  static const double GutterLeftExpanded = 75.0;

  static const double EdgeRadius = 4.0;
  static const double MinChildLength = 50.0;
  //static const double MarginLeft = GutterLeft + LineSpacing;
  static const double BubbleHeight = 50.0;
  static const double BubbleArrowSize = 19.0;
  static const double BubblePadding = 20.0;
  static const double BubbleTextHeight = 20.0;
  static const double AssetPadding = 30.0;
  static const double Parallax = 100.0;
  static const double AssetScreenScale = 0.3;
  static const double InitialViewportPadding = 100.0;
  static const double TravelViewportPaddingTop = 400.0;

  static const double ViewportPaddingTop = 120.0;
  static const double ViewportPaddingBottom = 100.0;
  static const int SteadyMilliseconds = 500;
  //static const double FadeAnimationStart = BubbleHeight + BubblePadding;///2.0 + BubblePadding;
  Simulation _scrollSimulation;
  ScrollPhysics _scrollPhysics;
  ScrollMetrics _scrollMetrics;

  double _simulationTime = 0.0;
  double _timeMin = 0.0;
  double _timeMax = 0.0;
  double _gutterWidth = GutterLeft;
  double get gutterWidth => _gutterWidth;

  EdgeInsets padding = EdgeInsets.zero;
  EdgeInsets devicePadding = EdgeInsets.zero;

  final TargetPlatform _platform;

  Timeline(this._platform) {
    setViewport(start: 1536.0, end: 3072.0);
  }
  double screenPaddingInTime(double padding, double start, double end) {
    return padding / computeScale(start, end);
  }

  double computeScale(double start, double end) {
    return _height == 0.0 ? 1.0 : _height / (end - start);
  }

  TimelineEntry get nextEntry => _renderNextEntry;
  double get nextEntryOpacity => _nextEntryOpacity;
  TimelineEntry get prevEntry => _renderPrevEntry;
  double get prevEntryOpacity => _prevEntryOpacity;

  Future<List<TimelineEntry>> loadFromBundle(String filename) async {
    List<TimelineEntry> allEntries = List<TimelineEntry>();
    String data = await rootBundle.loadString(filename);
    List jsonEntries = json.decode(data) as List;

    _backgroundColors = List<TimelineBackgroundColor>();
    _tickColors = List<TickColors>();
    _headerColors = List<HeaderColors>();
    for (dynamic entry in jsonEntries) {
      Map map = entry as Map;

      if (map != null) {
        TimelineEntry timelineEntry = TimelineEntry();
        if (map.containsKey("date")) {
          timelineEntry.type = TimelineEntryType.Incident;
          dynamic date = map["date"];
          timelineEntry.start = date is int ? date.toDouble() : date;
        } else if (map.containsKey("start")) {
          timelineEntry.type = TimelineEntryType.Era;
          dynamic start = map["start"];

          timelineEntry.start = start is int ? start.toDouble() : start;
        } else {
          continue;
        }

        if (map.containsKey("background")) {
          dynamic bg = map["background"];
          if (bg is List && bg.length >= 3) {
            _backgroundColors.add(TimelineBackgroundColor()
              ..color =
                  Color.fromARGB(255, bg[0] as int, bg[1] as int, bg[2] as int)
              ..start = timelineEntry.start);
          }
        }

        dynamic accent = map["accent"];
        if (accent is List && accent.length >= 3) {
          timelineEntry.accent = Color.fromARGB(
              accent.length > 3 ? accent[3] as int : 255,
              accent[0] as int,
              accent[1] as int,
              accent[2] as int);
        }

        if (map.containsKey("ticks")) {
          dynamic ticks = map["ticks"];
          if (ticks is Map) {
            Color bgColor = Colors.black;
            Color longColor = Colors.black;
            Color shortColor = Colors.black;
            Color textColor = Colors.black;

            dynamic bg = ticks["background"];
            if (bg is List && bg.length >= 3) {
              bgColor = Color.fromARGB(bg.length > 3 ? bg[3] as int : 255,
                  bg[0] as int, bg[1] as int, bg[2] as int);
            }
            dynamic long = ticks["long"];
            if (long is List && long.length >= 3) {
              longColor = Color.fromARGB(long.length > 3 ? long[3] as int : 255,
                  long[0] as int, long[1] as int, long[2] as int);
            }
            dynamic short = ticks["short"];
            if (short is List && short.length >= 3) {
              shortColor = Color.fromARGB(
                  short.length > 3 ? short[3] as int : 255,
                  short[0] as int,
                  short[1] as int,
                  short[2] as int);
            }
            dynamic text = ticks["text"];
            if (text is List && text.length >= 3) {
              textColor = Color.fromARGB(text.length > 3 ? text[3] as int : 255,
                  text[0] as int, text[1] as int, text[2] as int);
            }

            _tickColors.add(TickColors()
              ..background = bgColor
              ..long = longColor
              ..short = shortColor
              ..text = textColor
              ..start = timelineEntry.start
              ..screenY = 0.0);
          }
        }

        if (map.containsKey("header")) {
          dynamic header = map["header"];
          if (header is Map) {
            Color bgColor = Colors.black;
            Color textColor = Colors.black;

            dynamic bg = header["background"];
            if (bg is List && bg.length >= 3) {
              bgColor = Color.fromARGB(bg.length > 3 ? bg[3] as int : 255,
                  bg[0] as int, bg[1] as int, bg[2] as int);
            }
            dynamic text = header["text"];
            if (text is List && text.length >= 3) {
              textColor = Color.fromARGB(text.length > 3 ? text[3] as int : 255,
                  text[0] as int, text[1] as int, text[2] as int);
            }

            _headerColors.add(HeaderColors()
              ..background = bgColor
              ..text = textColor
              ..start = timelineEntry.start
              ..screenY = 0.0);
          }
        }

        if (map.containsKey("end")) {
          dynamic end = map["end"];
          timelineEntry.end = end is int ? end.toDouble() : end;
        } else if (timelineEntry.type == TimelineEntryType.Era) {
          timelineEntry.end = DateTime.now().year.toDouble() * 10.0;
        } else {
          timelineEntry.end = timelineEntry.start;
        }

        if (map.containsKey("label")) {
          timelineEntry.label = map["label"] as String;
        }
        if (map.containsKey("minScale")) {
          dynamic minScale = map["minScale"];
          timelineEntry.minScale =
              minScale is int ? minScale.toDouble() : minScale;
        }
        if (map.containsKey("id")) {
          timelineEntry.id = map["id"] as String;
          _entriesById[timelineEntry.id] = timelineEntry;
        }
        if (map.containsKey("article")) {
          timelineEntry.articleFilename = map["article"] as String;
        }

        if (map.containsKey("asset")) {
          TimelineAsset asset;
          Map assetMap = map["asset"] as Map;
          String source = assetMap["source"];
          String filename = "assets/" + source;
          String extension = getExtension(source);
          switch (extension) {
            case "flr":
              TimelineFlare flareAsset = TimelineFlare();
              asset = flareAsset;
              flare.FlutterActor actor = _flareResources[filename];
              if (actor == null) {
                actor = flare.FlutterActor();

                bool success = await actor.loadFromBundle(filename);
                if (success) {
                  _flareResources[filename] = actor;
                }
              }
              if (actor != null) {
                flareAsset.actorStatic = actor.artboard;
                flareAsset.actor = actor.artboard.makeInstance();
                flareAsset.animation = actor.artboard.animations[0];

                dynamic name = assetMap["idle"];
                if (name is String) {
                  if ((flareAsset.idle = flareAsset.actor.getAnimation(name)) !=
                      null) {
                    flareAsset.animation = flareAsset.idle;
                  }
                } else if (name is List) {
                  for (String animationName in name) {
                    flare.ActorAnimation animation =
                        flareAsset.actor.getAnimation(animationName);
                    if (animation != null) {
                      if (flareAsset.idleAnimations == null) {
                        flareAsset.idleAnimations =
                            List<flare.ActorAnimation>();
                      }
                      flareAsset.idleAnimations.add(animation);
                      flareAsset.animation = animation;
                    }
                  }
                }

                name = assetMap["intro"];
                if (name is String) {
                  if ((flareAsset.intro =
                          flareAsset.actor.getAnimation(name)) !=
                      null) {
                    flareAsset.animation = flareAsset.intro;
                  }
                }

                name = assetMap["mapNode"];
                if (name is String) {
                  flareAsset.mapNode = name;
                }

                flareAsset.animationTime = 0.0;
                flareAsset.actor.advance(0.0);

                flareAsset.setupAABB = flareAsset.actor.computeAABB();
                //print("${timelineEntry.label} ${flareAsset.setupAABB}");
                flareAsset.animation
                    .apply(flareAsset.animationTime, flareAsset.actor, 1.0);
                flareAsset.animation.apply(
                    flareAsset.animation.duration, flareAsset.actorStatic, 1.0);
                flareAsset.actor.advance(0.0);
                flareAsset.actorStatic.advance(0.0);
                //print("AABB $source ${flareAsset.setupAABB}");
                //nima.Vec2D size = nima.AABB.size(new nima.Vec2D(), flareAsset.setupAABB);
                //flareAsset.width = size[0];
                //flareAsset.height = size[1];
                dynamic loop = assetMap["loop"];
                flareAsset.loop = loop is bool ? loop : true;
                dynamic offset = assetMap["offset"];
                flareAsset.offset = offset == null
                    ? 0.0
                    : offset is int ? offset.toDouble() : offset;
                dynamic gap = assetMap["gap"];
                flareAsset.gap =
                    gap == null ? 0.0 : gap is int ? gap.toDouble() : gap;

                dynamic bounds = assetMap["bounds"];
                if (bounds is List) {
                  flareAsset.setupAABB = flare.AABB.fromValues(
                      bounds[0] is int ? bounds[0].toDouble() : bounds[0],
                      bounds[1] is int ? bounds[1].toDouble() : bounds[1],
                      bounds[2] is int ? bounds[2].toDouble() : bounds[2],
                      bounds[3] is int ? bounds[3].toDouble() : bounds[3]);
                  //print("UPDATE ${flareAsset.setupAABB}");
                }
              }
              break;
            case "nma":
              TimelineNima nimaAsset = TimelineNima();
              asset = nimaAsset;
              nima.FlutterActor actor = _nimaResources[filename];
              if (actor == null) {
                actor = nima.FlutterActor();

                bool success = await actor.loadFromBundle(filename);
                if (success) {
                  _nimaResources[filename] = actor;
                }
              }
              if (actor != null) {
                nimaAsset.actorStatic = actor;
                nimaAsset.actor = actor.makeInstance();

                dynamic name = assetMap["idle"];
                if (name is String) {
                  nimaAsset.animation = nimaAsset.actor.getAnimation(name);
                } else {
                  nimaAsset.animation = actor.animations[0];
                }
                nimaAsset.animationTime = 0.0;
                nimaAsset.actor.advance(0.0);

                nimaAsset.setupAABB = nimaAsset.actor.computeAABB();
                //print("${timelineEntry.label} ${nimaAsset.setupAABB}");
                nimaAsset.animation
                    .apply(nimaAsset.animationTime, nimaAsset.actor, 1.0);
                nimaAsset.animation.apply(
                    nimaAsset.animation.duration, nimaAsset.actorStatic, 1.0);
                nimaAsset.actor.advance(0.0);
                nimaAsset.actorStatic.advance(0.0);
                //print("AABB $source ${nimaAsset.setupAABB}");
                //nima.Vec2D size = nima.AABB.size(new nima.Vec2D(), nimaAsset.setupAABB);
                //nimaAsset.width = size[0];
                //nimaAsset.height = size[1];
                dynamic loop = assetMap["loop"];
                nimaAsset.loop = loop is bool ? loop : true;
                dynamic offset = assetMap["offset"];
                nimaAsset.offset = offset == null
                    ? 0.0
                    : offset is int ? offset.toDouble() : offset;
                dynamic gap = assetMap["gap"];
                nimaAsset.gap =
                    gap == null ? 0.0 : gap is int ? gap.toDouble() : gap;
                dynamic bounds = assetMap["bounds"];
                if (bounds is List) {
                  nimaAsset.setupAABB = nima.AABB.fromValues(
                      bounds[0] is int ? bounds[0].toDouble() : bounds[0],
                      bounds[1] is int ? bounds[1].toDouble() : bounds[1],
                      bounds[2] is int ? bounds[2].toDouble() : bounds[2],
                      bounds[3] is int ? bounds[3].toDouble() : bounds[3]);
                }
              }
              break;

            default:
              TimelineImage imageAsset = TimelineImage();
              asset = imageAsset;

              ByteData data = await rootBundle.load(filename);
              Uint8List list = Uint8List.view(data.buffer);
              ui.Codec codec = await ui.instantiateImageCodec(list);
              ui.FrameInfo frame = await codec.getNextFrame();
              imageAsset.image = frame.image;

              break;
          }

          double scale = 1.0;
          if (assetMap.containsKey("scale")) {
            dynamic s = assetMap["scale"];
            scale = s is int ? s.toDouble() : s;
          }

          dynamic width = assetMap["width"];
          asset.width = (width is int ? width.toDouble() : width) * scale;

          dynamic height = assetMap["height"];
          asset.height = (height is int ? height.toDouble() : height) * scale;
          asset.entry = timelineEntry;
          asset.filename = filename;
          //print("ENTRY ${timelineEntry.label} $asset");
          timelineEntry.asset = asset;
        }
        allEntries.add(timelineEntry);
      }
    }

    VideoPlayerController controller =
        VideoPlayerController.network(videoStreamUrl);
    controller.initialize().then((_) {
      controller.setVolume(0.0);
    });

    watchPartyEntry = TimelineEntry()
      ..type = TimelineEntryType.Incident
      ..start = 2018.9
      ..end = 2018.9
      ..label = "Flutter Live"
      ..asset = (TimelineWatchParty()
        ..width = 624
        ..height = 354
        ..playerController = controller);
    watchPartyEntry.asset.entry = watchPartyEntry;

    allEntries.add(watchPartyEntry);
    // sort the full list so they are in order of oldest to newest
    allEntries.sort((TimelineEntry a, TimelineEntry b) {
      return a.start.compareTo(b.start);
    });

    _backgroundColors
        .sort((TimelineBackgroundColor a, TimelineBackgroundColor b) {
      return a.start.compareTo(b.start);
    });

    _timeMin = double.maxFinite;
    _timeMax = -double.maxFinite;
    _entries = List<TimelineEntry>();
    // build up hierarchy (eras are grouped into spanning eras and events are placed into the eras they belong to)
    TimelineEntry previous;
    for (TimelineEntry entry in allEntries) {
      if (entry.start < _timeMin) {
        _timeMin = entry.start;
      }
      if (entry.end > _timeMax) {
        _timeMax = entry.end;
      }
      if (previous != null) {
        previous.next = entry;
      }
      entry.previous = previous;
      previous = entry;

      TimelineEntry parent;
      double minDistance = double.maxFinite;
      for (TimelineEntry checkEntry in allEntries) {
        if (checkEntry.type == TimelineEntryType.Era) {
          double distance = entry.start - checkEntry.start;
          double distanceEnd = entry.start - checkEntry.end;
          if (distance > 0 && distanceEnd < 0 && distance < minDistance) {
            minDistance = distance;
            parent = checkEntry;
          }
        }
      }
      if (parent != null) {
        entry.parent = parent;
        if (parent.children == null) {
          parent.children = List<TimelineEntry>();
        }
        parent.children.add(entry);
      } else {
        // item doesn't  have a parent, so it's one of our root entries.
        _entries.add(entry);
      }
    }
    return allEntries;
  }

  TimelineEntry getById(String id) {
    return _entriesById[id];
  }

  clampScroll() {
    _scrollMetrics = null;
    _scrollPhysics = null;
    _scrollSimulation = null;

    double scale = computeScale(_start, _end);
    double padTop = (devicePadding.top + ViewportPaddingTop) / scale;
    double padBottom = (devicePadding.bottom + ViewportPaddingBottom) / scale;
    bool fixStart = _start < _timeMin - padTop;
    bool fixEnd = _end > _timeMax + padBottom;

    // As the scale changes we need to re-solve the right padding
    // Don't think there's an analytical single solution for this
    // so we do it in steps approaching the correct answer.
    for (int i = 0; i < 20; i++) {
      double scale = computeScale(_start, _end);
      double padTop = (devicePadding.top + ViewportPaddingTop) / scale;
      double padBottom = (devicePadding.bottom + ViewportPaddingBottom) / scale;
      if (fixStart) {
        _start = _timeMin - padTop;
      }
      if (fixEnd) {
        _end = _timeMax + padBottom;
      }
    }
    if (_end < _start) {
      _end = _start + _height / scale;
    }
    // _start = max(_start, _first.start - padTop);
    // _end = min(_end, _last.end + padBottom);
    if (!_isFrameScheduled) {
      _isFrameScheduled = true;
      _lastFrameTime = 0.0;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    }
  }

  void setViewport(
      {double start = double.maxFinite,
      bool pad = false,
      double end = double.maxFinite,
      double height = double.maxFinite,
      double width = double.maxFinite,
      double velocity = double.maxFinite,
      bool animate = false}) {
    if (height != double.maxFinite) {
      if (_height == 0.0 && _entries != null && _entries.length > 0) {
        double scale = height / (_end - _start);
        _start = _start - padding.top / scale;
        _end = _end + padding.bottom / scale;
      }
      _height = height;
    }
    if (width != double.maxFinite) {
      _width = width;
    }
    if (start != double.maxFinite && end != double.maxFinite) {
      _start = start;
      _end = end;
      if (pad && _height != 0.0) {
        double scale = _height / (_end - _start);
        _start = _start - padding.top / scale;
        _end = _end + padding.bottom / scale;
      }
    } else {
      if (start != double.maxFinite) {
        double scale = height / (_end - _start);
        _start = pad ? start - padding.top / scale : start;
      }
      if (end != double.maxFinite) {
        double scale = height / (_end - _start);
        _end = pad ? end + padding.bottom / scale : end;
      }
    }

    if (velocity != double.maxFinite) {
      double scale = computeScale(_start, _end);
      double padTop =
          (devicePadding.top + ViewportPaddingTop) / computeScale(_start, _end);
      double padBottom = (devicePadding.bottom + ViewportPaddingBottom) /
          computeScale(_start, _end);
      double rangeMin = (_timeMin - padTop) * scale;
      double rangeMax = (_timeMax + padBottom) * scale - _height;
      if (rangeMax < rangeMin) {
        rangeMax = rangeMin;
      }
      double position = _start * scale;
      //  Conver to pixels...

      //_velocity = velocity;
      _simulationTime = 0.0;
      if (_platform == TargetPlatform.iOS) {
        _scrollPhysics = BouncingScrollPhysics();
      } else {
        _scrollPhysics = ClampingScrollPhysics();
      }
      _scrollMetrics = FixedScrollMetrics(
          minScrollExtent: double.negativeInfinity,
          maxScrollExtent: double.infinity,
          pixels: 0.0,
          // minScrollExtent: rangeMin,
          // maxScrollExtent: rangeMax,
          // pixels: position,
          viewportDimension: _height,
          axisDirection: AxisDirection.down);

      _scrollSimulation =
          _scrollPhysics.createBallisticSimulation(_scrollMetrics, velocity);
    }
    if (!animate) {
      _renderStart = start;
      _renderEnd = end;
      advance(0.0, false);
      if (onNeedPaint != null) {
        onNeedPaint();
      }
    } else if (!_isFrameScheduled) {
      _isFrameScheduled = true;
      _lastFrameTime = 0.0;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    }
  }

  void beginFrame(Duration timeStamp) {
    _isFrameScheduled = false;
    final double t =
        timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
    if (_lastFrameTime == 0.0) {
      _lastFrameTime = t;
      _isFrameScheduled = true;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
      return;
    }

    double elapsed = t - _lastFrameTime;
    _lastFrameTime = t;

    if (!advance(elapsed, true) && !_isFrameScheduled) {
      _isFrameScheduled = true;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    }

    if (onNeedPaint != null) {
      onNeedPaint();
    }
  }

  TickColors findTickColors(double screen) {
    if (_tickColors == null) {
      return null;
    }
    for (TickColors color in _tickColors.reversed) {
      if (screen >= color.screenY) {
        return color;
      }
    }

    return screen < _tickColors.first.screenY
        ? _tickColors.first
        : _tickColors.last;
  }

  HeaderColors findHeaderColors(double screen) {
    if (_headerColors == null) {
      return null;
    }
    for (HeaderColors color in _headerColors.reversed) {
      if (screen >= color.screenY) {
        return color;
      }
    }

    return screen < _headerColors.first.screenY
        ? _headerColors.first
        : _headerColors.last;
  }

  bool advance(double elapsed, bool animate) {
    if (_height <= 0) {
      // Done rendering. Need to wait for height.
      return true;
    }
    double scale = _height / (_renderEnd - _renderStart);

    bool doneRendering = true;
    bool stillScaling = true;
    // Attenuate velocity and displace targets.
    // _velocity *= 1.0 - min(1.0, elapsed*Deceleration);
    // double displace = _velocity*elapsed;
    // _start -= displace;
    // _end -= displace;

    if (_scrollSimulation != null) {
      doneRendering = false;
      _simulationTime += elapsed;
      double scale = _height / (_end - _start);
      // double range = _end-_start;
      // double value = _scrollSimulation.x(_simulationTime);
      // double overScroll = _scrollPhysics.applyBoundaryConditions(_scrollMetrics, value);
      // _start = (value-overScroll)/scale;
      // _end = _start + range;
      double velocity = _scrollSimulation.dx(_simulationTime);

      double displace = velocity * elapsed / scale;

      _start -= displace;
      _end -= displace;

      if (_scrollSimulation.isDone(_simulationTime)) {
        _scrollMetrics = null;
        _scrollPhysics = null;
        _scrollSimulation = null;
      }
    }

    double targetGutterWidth = _showFavorites ? GutterLeftExpanded : GutterLeft;
    double dgw = targetGutterWidth - _gutterWidth;
    if (!animate || dgw.abs() < 1) {
      _gutterWidth = targetGutterWidth;
    } else {
      doneRendering = false;
      _gutterWidth += dgw * min(1.0, elapsed * 10.0);
    }

    // Animate movement.
    double speed =
        min(1.0, elapsed * (_isInteracting ? MoveSpeedInteracting : MoveSpeed));
    double ds = _start - _renderStart;
    double de = _end - _renderEnd;

    if (!animate || ((ds * scale).abs() < 1.0 && (de * scale).abs() < 1.0)) {
      stillScaling = false;
      _renderStart = _start;
      _renderEnd = _end;
    } else {
      doneRendering = false;
      _renderStart += ds * speed;
      _renderEnd += de * speed;
    }
    isScaling = stillScaling;

    // Update scale after changing render range.
    scale = _height / (_renderEnd - _renderStart);
    // Update color screen positions.

    if (_tickColors != null && _tickColors.length > 0) {
      double lastStart = _tickColors.first.start;
      for (TickColors color in _tickColors) {
        color.screenY =
            (lastStart + (color.start - lastStart / 2.0) - _renderStart) *
                scale;
        lastStart = color.start;
      }
    }
    if (_headerColors != null && _headerColors.length > 0) {
      double lastStart = _headerColors.first.start;
      for (HeaderColors color in _headerColors) {
        color.screenY =
            (lastStart + (color.start - lastStart / 2.0) - _renderStart) *
                scale;
        lastStart = color.start;
      }
    }

    _currentHeaderColors = findHeaderColors(0.0);

    if (_currentHeaderColors != null) {
      if (_headerTextColor == null) {
        _headerTextColor = _currentHeaderColors.text;
        _headerBackgroundColor = _currentHeaderColors.background;
      } else {
        bool stillColoring = false;
        Color headerTextColor = interpolateColor(
            _headerTextColor, _currentHeaderColors.text, elapsed);

        if (headerTextColor != _headerTextColor) {
          _headerTextColor = headerTextColor;
          stillColoring = true;
          doneRendering = false;
        }
        Color headerBackgroundColor = interpolateColor(
            _headerBackgroundColor, _currentHeaderColors.background, elapsed);
        if (headerBackgroundColor != _headerBackgroundColor) {
          _headerBackgroundColor = headerBackgroundColor;
          stillColoring = true;
          doneRendering = false;
        }
        if (stillColoring) {
          if (onHeaderColorsChanged != null) {
            onHeaderColorsChanged(_headerBackgroundColor, _headerTextColor);
          }
        }
      }
    }

    _lastEntryY = -double.maxFinite;
    _lastOnScreenEntryY = 0.0;
    _firstOnScreenEntryY = double.maxFinite;
    _lastAssetY = -double.maxFinite;
    _labelX = 0.0;
    _offsetDepth = 0.0;
    _currentEra = null;
    _nextEntry = null;
    _prevEntry = null;
    if (_entries != null) {
      if (advanceItems(
          _entries, _gutterWidth + LineSpacing, scale, elapsed, animate, 0)) {
        doneRendering = false;
      }

      _renderAssets = List<TimelineAsset>();
      if (advanceAssets(_entries, elapsed, animate, _renderAssets)) {
        doneRendering = false;
      }
    }

    if (_nextEntryOpacity == 0.0) {
      _renderNextEntry = _nextEntry;
    }

    double targetNextEntryOpacity = _lastOnScreenEntryY > _height / 1.7 ||
            !_isSteady ||
            _distanceToNextEntry < 0.01 ||
            _nextEntry != _renderNextEntry
        ? 0.0
        : 1.0;
    double dt = targetNextEntryOpacity - _nextEntryOpacity;

    if (!animate || dt.abs() < 0.01) {
      _nextEntryOpacity = targetNextEntryOpacity;
    } else {
      doneRendering = false;
      _nextEntryOpacity += dt * min(1.0, elapsed * 10.0);
    }

    if (_prevEntryOpacity == 0.0) {
      _renderPrevEntry = _prevEntry;
    }

    double targetPrevEntryOpacity = _firstOnScreenEntryY < _height / 2.0 ||
            !_isSteady ||
            _distanceToPrevEntry < 0.01 ||
            _prevEntry != _renderPrevEntry
        ? 0.0
        : 1.0;
    dt = targetPrevEntryOpacity - _prevEntryOpacity;

    if (!animate || dt.abs() < 0.01) {
      _prevEntryOpacity = targetPrevEntryOpacity;
    } else {
      doneRendering = false;
      _prevEntryOpacity += dt * min(1.0, elapsed * 10.0);
    }

    double dl = _labelX - _renderLabelX;
    if (!animate || dl.abs() < 1.0) {
      _renderLabelX = _labelX;
    } else {
      doneRendering = false;
      _renderLabelX += dl * min(1.0, elapsed * 6.0);
    }

    if (_currentEra != _lastEra) {
      _lastEra = _currentEra;
      if (onEraChanged != null) {
        onEraChanged(_currentEra);
      }
    }

    if (_isSteady) {
      double dd = _offsetDepth - renderOffsetDepth;
      if (!animate || dd.abs() * DepthOffset < 1.0) {
        _renderOffsetDepth = _offsetDepth;
      } else {
        doneRendering = false;
        _renderOffsetDepth += dd * min(1.0, elapsed * 12.0);
      }
    }

    int heartCount = 0;
    const int MaxHearts = 140;
    const int MaxHeartsPerFrame = 2;
    const double HeartTime = 1.5;
    const double HeartSize = 22.0;
    const double HeartFade = 0.5;

    if (hearts.isNotEmpty) {
      Heart heart = hearts.first;
      while (heart != null) {
        double heartTime = heart.duration;
        double heartFadeOut = heartTime - HeartFade;

        heart.elapsed += elapsed;
        heart.opacity = heart.elapsed > heartFadeOut
            ?
            // Fading out
            1.0 - (heart.elapsed - heartFadeOut).clamp(0.0, 1.0)
            :
            // Fading in
            (heart.elapsed / 0.5).clamp(0.0, 1.0);

        Heart next = heart.next;
        if (heart.elapsed > heartTime) {
          hearts.remove(heart);
        } else {
          heartCount++;
        }
        heart = next;
      }
    }
    if (addHearts && heartCount < MaxHearts) {
      Random random = Random();

      for (int i = 0; i < MaxHeartsPerFrame && heartCount < MaxHearts; i++) {
        int layer = random.nextInt(4);

        double heartTimeRange = (HeartSize + (HeartSize * layer / 4.0)) /
            computeScale(renderStart, renderEnd);
        double start =
            renderStart + (renderEnd - renderStart) * random.nextDouble();
        Heart heart = Heart()
          ..start = start
          ..end = start + heartTimeRange
          ..x = random.nextDouble()
          ..elapsed = 0
          ..duration = HeartTime + random.nextDouble()
          ..phase = random.nextDouble()
          ..layer = layer
          ..opacity = 0;
        hearts.add(heart);
        heartCount++;
      }
    }
    if (heartCount > 0) {
      doneRendering = false;
    }

    return doneRendering;
  }

  double bubbleHeight(TimelineEntry entry) {
    return BubblePadding * 2.0 + entry.lineCount * BubbleTextHeight;
  }

  bool advanceItems(List<TimelineEntry> items, double x, double scale,
      double elapsed, bool animate, int depth) {
    bool stillAnimating = false;
    double lastEnd = -double.maxFinite;
    for (int i = 0; i < items.length; i++)
    //for(TimelineEntry item in items)
    {
      TimelineEntry item = items[i];

      double start = item.start - _renderStart;
      double end =
          item.type == TimelineEntryType.Era ? item.end - _renderStart : start;
      // double length = (end-start)*scale-2*EdgePadding;
      // double pad = EdgePadding;//(length/EdgePadding).clamp(0.0, 1.0)*EdgePadding;

      //item.length = length = max(0.0, (end-start)*scale-pad*2.0);
      // if(item.label == "Lost Filip")
      // {
      // 	print("SCALE $scale");
      // }
      double y = start * scale; //+pad;
      if (i > 0 && y - lastEnd < EdgePadding) {
        y = lastEnd + EdgePadding;
      }
      double endY = end * scale; //-pad;
      lastEnd = endY;

      item.length = endY - y;
      double targetLabelY = y;
      double itemBubbleHeight = bubbleHeight(item);
      double fadeAnimationStart = itemBubbleHeight + BubblePadding / 2.0;
      if (targetLabelY - _lastEntryY < fadeAnimationStart
          // The best location for our label is occluded, lets see if we can bump it forward...
          &&
          item.type == TimelineEntryType.Era &&
          _lastEntryY + fadeAnimationStart < endY) {
        targetLabelY = _lastEntryY + fadeAnimationStart + 0.5;
      }

      double targetLabelOpacity =
          targetLabelY - _lastEntryY < fadeAnimationStart ? 0.0 : 1.0;
      if (item.minScale != null && scale < item.minScale) {
        targetLabelOpacity = 0.0;
      }
      // Debounce labels becoming visible.
      if (targetLabelOpacity > 0.0 && item.targetLabelOpacity != 1.0) {
        item.delayLabel = 0.5;
      }
      item.targetLabelOpacity = targetLabelOpacity;
      if (item.delayLabel > 0.0) {
        targetLabelOpacity = 0.0;
        item.delayLabel -= elapsed;
        stillAnimating = true;
      }

      double dt = targetLabelOpacity - item.labelOpacity;
      if (!animate || dt.abs() < 0.01) {
        item.labelOpacity = targetLabelOpacity;
      } else {
        stillAnimating = true;
        item.labelOpacity += dt * min(1.0, elapsed * 25.0);
      }

      item.y = y;
      item.endY = endY;

      double targetLegOpacity = item.length > EdgeRadius ? 1.0 : 0.0;
      double dtl = targetLegOpacity - item.legOpacity;
      if (!animate || dtl.abs() < 0.01) {
        item.legOpacity = targetLegOpacity;
      } else {
        stillAnimating = true;
        item.legOpacity += dtl * min(1.0, elapsed * 20.0);
      }

      double targetItemOpacity = item.parent != null
          ? item.parent.length < MinChildLength ||
                  (item.parent != null && item.parent.endY < y)
              ? 0.0
              : y > item.parent.y ? 1.0 : 0.0
          : 1.0;
      dtl = targetItemOpacity - item.opacity;
      if (!animate || dtl.abs() < 0.01) {
        item.opacity = targetItemOpacity;
      } else {
        stillAnimating = true;
        item.opacity += dtl * min(1.0, elapsed * 20.0);
      }

      // if(item.labelY === undefined)
      // {
      // 	item.labelY = y;
      // }

      double targetLabelVelocity = targetLabelY - item.labelY;
      // if(item.velocity === undefined)
      // {
      // 	item.velocity = 0.0;
      // }
      double dvy = targetLabelVelocity - item.labelVelocity;
      if (dvy.abs() > _height) {
        item.labelY = targetLabelY;
        item.labelVelocity = 0.0;
      } else {
        item.labelVelocity += dvy * elapsed * 18.0;
        item.labelY += item.labelVelocity * elapsed * 20.0;
      }
      if (animate &&
          (item.labelVelocity.abs() > 0.01 ||
              targetLabelVelocity.abs() > 0.01)) {
        stillAnimating = true;
      }

      if (item.targetLabelOpacity > 0.0) {
        _lastEntryY = targetLabelY;
        if (_lastEntryY < _height && _lastEntryY > devicePadding.top) {
          _lastOnScreenEntryY = _lastEntryY;
          if (_firstOnScreenEntryY == double.maxFinite) {
            _firstOnScreenEntryY = _lastEntryY;
          }
        }
      }

      if (item.type == TimelineEntryType.Era &&
          y < 0 &&
          endY > _height &&
          depth > _offsetDepth) {
        _offsetDepth = depth.toDouble();
      }
      if (item.type == TimelineEntryType.Era && y < 0 && endY > _height / 2.0) {
        _currentEra = item;
      }

      // Check if the bubble is out of view and set the y position to the
      // target one directly.
      if (y > _height + itemBubbleHeight) {
        item.labelY = y;
        if (_nextEntry == null) {
          _nextEntry = item;
          _distanceToNextEntry = (y - _height) / _height;
        }
      } else if (endY < devicePadding.top) {
        _prevEntry = item;
        _distanceToPrevEntry = ((y - _height) / _height).abs();
      } else if (endY < -itemBubbleHeight) {
        item.labelY = y;
      }

      double lx = x + LineSpacing + LineSpacing;
      if (lx > _labelX) {
        _labelX = lx;
      }

      if (item.children != null && item.isVisible) {
        if (advanceItems(item.children, x + LineSpacing + LineWidth, scale,
            elapsed, animate, depth + 1)) {
          stillAnimating = true;
        }
      }
    }
    return stillAnimating;
  }

  bool advanceAssets(List<TimelineEntry> items, double elapsed, bool animate,
      List<TimelineAsset> renderAssets) {
    bool stillAnimating = false;
    for (TimelineEntry item in items) {
      if (item.asset != null) {
        double y = item.labelY;
        double halfHeight = _height / 2.0;
        double thresholdAssetY = y +
            ((y - halfHeight) / halfHeight) *
                Parallax; //item.asset.height*AssetScreenScale/2.0;
        double targetAssetY =
            thresholdAssetY - item.asset.height * AssetScreenScale / 2.0;
        double targetAssetOpacity =
            (thresholdAssetY - _lastAssetY < 0 ? 0.0 : 1.0) *
                item.opacity *
                item.labelOpacity;

        // Debounce asset becoming visible.
        if (targetAssetOpacity > 0.0 && item.targetAssetOpacity != 1.0) {
          item.delayAsset = 0.25;
        }
        item.targetAssetOpacity = targetAssetOpacity;
        if (item.delayAsset > 0.0) {
          targetAssetOpacity = 0.0;
          item.delayAsset -= elapsed;
          stillAnimating = true;
        }

        double targetScale = targetAssetOpacity;
        double targetScaleVelocity = targetScale - item.asset.scale;
        if (!animate || targetScale == 0) {
          item.asset.scaleVelocity = targetScaleVelocity;
        } else {
          double dvy = targetScaleVelocity - item.asset.scaleVelocity;
          item.asset.scaleVelocity += dvy * elapsed * 18.0;
        }

        item.asset.scale += item.asset.scaleVelocity *
            elapsed *
            20.0; //Math.min(1.0, elapsed*(10.0+f*35));
        if (animate &&
            (item.asset.scaleVelocity.abs() > 0.01 ||
                targetScaleVelocity.abs() > 0.01)) {
          stillAnimating = true;
        }

        TimelineAsset asset = item.asset;
        if (asset.opacity == 0.0) {
          // Item was invisible, just pop it to the right place and stop velocity.
          asset.y = targetAssetY;
          asset.velocity = 0.0;
        }
        double da = targetAssetOpacity - asset.opacity;
        if (!animate || da.abs() < 0.01) {
          asset.opacity = targetAssetOpacity;
        } else {
          stillAnimating = true;
          asset.opacity += da * min(1.0, elapsed * 15.0);
        }

        if (asset.opacity > 0.0) // visible
        {
          // if(asset.y === undefined)
          // {
          // 	asset.y = Math.max(this._lastAssetY, targetAssetY);
          // }

          double targetAssetVelocity = max(_lastAssetY, targetAssetY) - asset.y;
          double dvay = targetAssetVelocity - asset.velocity;
          if (dvay.abs() > _height) {
            asset.y = targetAssetY;
            asset.velocity = 0.0;
          } else {
            asset.velocity += dvay * elapsed * 15.0;
            asset.y += asset.velocity * elapsed * 17.0;
          }
          if (asset.velocity.abs() > 0.01 || targetAssetVelocity.abs() > 0.01) {
            stillAnimating = true;
          }

          _lastAssetY = /*assetY*/ targetAssetY +
              asset.height * AssetScreenScale /*renderScale(asset.scale)*/ +
              AssetPadding;
          if (asset is TimelineNima) {
            _lastAssetY += asset.gap;
          } else if (asset is TimelineFlare) {
            _lastAssetY += asset.gap;
          }
          if (asset.y > _height ||
              asset.y + asset.height * AssetScreenScale < 0.0) {
            // Cull it, it's not in view. Make sure we don't advance animations.
            if (asset is TimelineNima) {
              TimelineNima nimaAsset = asset;
              if (!nimaAsset.loop) {
                nimaAsset.animationTime = -1.0;
              }
            } else if (asset is TimelineFlare) {
              TimelineFlare flareAsset = asset;
              if (!flareAsset.loop) {
                flareAsset.animationTime = -1.0;
              } else if (flareAsset.intro != null) {
                flareAsset.animationTime = -1.0;
                flareAsset.animation = flareAsset.intro;
              }
            }
          } else {
            if (asset is TimelineNima && isActive) {
              asset.animationTime += elapsed;
              if (asset.loop) {
                asset.animationTime %= asset.animation.duration;
              }
              asset.animation.apply(asset.animationTime, asset.actor, 1.0);
              asset.actor.advance(elapsed);
              stillAnimating = true;
            } else if (asset is TimelineFlare && isActive) {
              asset.animationTime += elapsed;
              if (asset.idleAnimations != null) {
                double phase = 0.0;
                for (flare.ActorAnimation animation in asset.idleAnimations) {
                  animation.apply(
                      (asset.animationTime + phase) % animation.duration,
                      asset.actor,
                      1.0);
                  phase += 0.16;
                }
              } else {
                if (asset.intro == asset.animation &&
                    asset.animationTime >= asset.animation.duration) {
                  asset.animationTime -= asset.animation.duration;
                  asset.animation = asset.idle;
                }
                if (asset.loop && asset.animationTime > 0) {
                  asset.animationTime %= asset.animation.duration;
                }
                asset.animation.apply(asset.animationTime, asset.actor, 1.0);
              }
              asset.actor.advance(elapsed);
              stillAnimating = true;
            }

            renderAssets.add(item.asset);
          }
        } else {
          item.asset.y = max(_lastAssetY, targetAssetY);
        }
      }

      if (item.children != null && item.isVisible) {
        if (advanceAssets(item.children, elapsed, animate, renderAssets)) {
          stillAnimating = true;
        }
      }
    }
    return stillAnimating;
  }
}
