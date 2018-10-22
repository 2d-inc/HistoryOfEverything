import 'timeline/timeline_widget.dart';
import 'main_menu/main_menu.dart';
import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget  {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {

	bool _isTimelineActive = false;
	AnimationController _controller;
	static final Animatable<Offset> _slideTween = Tween<Offset>(
		begin: const Offset(0.0, 0.0),
		end: const Offset(-1.0, 0.0),
	).chain(CurveTween(
		curve: Curves.fastOutSlowIn,
	));


	Animation<Offset> _menuOffset;
	initState()
	{
		super.initState();
		_controller = AnimationController(
			vsync: this,
			duration: const Duration(milliseconds: 200),
		);
		_menuOffset = _controller.drive(_slideTween);						
	}


	void _onHideMenu()
	{
		_controller.forward().whenComplete(()
		{
			setState(() 
			{
				_isTimelineActive = true;
			});
		});
	}

	void _onShowMenu()
    {
		_controller.reverse().whenComplete(()
		{
			setState(() 
			{
				_isTimelineActive = false;
			});
		});
    }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return new Scaffold(
      	appBar: null,
      	body: new Stack(
		  children: <Widget> [
			  Positioned.fill( child: TimelineWidget( showMenu: _onShowMenu, isActive:_isTimelineActive )),
			  Positioned.fill( child: SlideTransition(position: _menuOffset, child:MainMenuWidget(selectItem: _onHideMenu) ))
		  ]
		)
    );
  }
}

/*

    return new Scaffold(
		drawer: SizedBox.expand(
			child: new Drawer(
				child: MainMenuWidget(selectItem: _onShowMenu),
      		),
		),
      	appBar: new AppBar(
        	title: new Text("Timeline"),
      	),
      	body: new Stack(
		  children: <Widget> [
			  Positioned.fill( child: TimelineWidget() ),
			  //Positioned.fill( left: _menuOffset, right: -_menuOffset, child: MainMenuWidget(selectItem: _onShowMenu) )
		  ]
		)
    );*/