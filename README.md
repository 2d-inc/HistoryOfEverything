# The History of Everything

<img align="right" src="https://cdn.2dimensions.com/1_Start.gif" height="400">

The History of Everything is a vertical timeline that allows you to navigate, explore, and compare events from the Big Bang to the birth of the Internet. Events are beautifully illustrated and animated.

The concept for this app was inspired by the Kurzgesagt video, [Time: The History & Future of Everything](https://www.youtube.com/watch?v=5TbUxGZtwGI).

The app was built with [Flutter](https://flutter.io/) by [2Dimensions](https://www.2dimensions.com) and it's available on [Android](https://play.google.com/store/apps/details?id=com.twodimensions.timeline) and [iOS](https://itunes.apple.com/us/app/the-history-of-everything/id1441257460).

## Usage

Make sure you have Flutter installed on your local machine. For more instructions on how to install flutter, look [here](https://flutter.io/docs/get-started/install).
```
git clone https://github.com/2d-inc/HistoryOfEverything.git
cd HistoryOfEverything/app
git submodule init
git submodule update
flutter run
```

## Overview
<img align="right" src="https://cdn.2dimensions.com/2_Scroll.gif" height="400">

The app consists of three main views:

1. **Main Menu** - /app/lib/main_menu<br />
This is the initial view for the app when it opens up. It shows a search bar on top, three menu sections for each major time era, and three buttons on the bottom for accessing favorites, sharing a link to the store, and the about page.<br />

2. **Timeline** - /app/lib/timeline<br />
This view is displayed when an item from the menu is selected: the user is presented with a vertical timeline. It can be scrolled up and down, zoomed in and out. <br/>
When an event is in view, a bubble will be shown on screen with a custom animated widget right next to it. By tapping on either, the user can access the ArticlePage.

3. **ArticlePage** - /app/lib/article<br />
The ArticlePage displays the event animation, together with a full description of the event.<br/>

## Animated Widgets

<img align="right" src="https://cdn.2dimensions.com/3_Amelia.gif" height="400">

This relies heavily on the animations built on [2dimensions](https://www.2dimensions.com) and they are seamlessly integrated with Flutter by using the [Flare](https://pub.dartlang.org/packages/flare_flutter) and [Nima](https://pub.dartlang.org/packages/nima) libraries.

One of Flutter's biggest strengths is its flexibility, because it exposes the architecture of its components, which can be built entirely from scratch: it's possible to create custom widgets out of the SDK's most basic elements. 

An example can be found in /app/lib/article/timeline_entry_widget.dart <br/>
This file contains two classes:<br/>
- `TimelineEntryWidget` that extends `LeafRenderObjectWidget`
- VignetteRenderObject that extends `RenderBox`

## LeafRenderObjectWidget

This class ([docs](https://docs.flutter.io/flutter/widgets/LeafRenderObjectWidget-class.html)) is a `Widget`: it can be inserted in any widget tree without any other default component: 

```
Container(
  child: TimelineEntryWidget(
        isActive: true,
        timelineEntry: widget.article,
        interactOffset: _interactOffset
    )
)
```

This snippet is used in /app/lib/article/article_widget.dart

The `LeafRenderObjectWidget` is responsible for having a constructor and encapsulating the values that the `RenderObject` needs.

The following two overrides are also fundamental:
- `createRenderObject()` <br />
Instantiates the actual `RenderObject` in the Widget Tree;
- `updateRenderObject()` <br />
Any change to the parameters that are passed to the Widget can be reflected also on the UI, if needed. Updating a `RenderObject` will cause the object to redraw.

## RenderObject

As specified in the [docs](https://docs.flutter.io/flutter/rendering/RenderObject-class.html), this is an object in the render tree, and it defines what and how its creator Widget will paint on the screen.

The key override here is `paint()`:<br />
&nbsp;&nbsp;&nbsp;&nbsp;the current `PaintingContext` exposes the `canvas`, and this class can draw, taking full advantage of the exposed API. <br />
The [Flare library](https://pub.dartlang.org/packages/flare_flutter), granted access to the `canvas`, draws the animation.<br/>
To have the animation reproduce correctly, it's also necessary to call `advance(elapsed)` on the current `FlutterActor` each frame. Moreover, the current `ActorAnimation` requires that the function `apply(time)` is called on it to display it's correct interpolated values.<br/>
This is all made possible by relying on Flutter's `SchedulerBinding.scheduleFrameCallback()`.

This is just a brief overview of how the Flare widgets can be customized for every experience.

## License
All the animations in the `/assets` folder are distributed under the **CC-BY** license.

All the articles in `assets/articles` are from [Wikipedia](https://www.wikipedia.org/), and are thus distributed under the **GNU Free Documentation License**.

The rest of the repository's code and contents are distributed under the **MIT** license as specified in [LICENSE](LICENSE).
