import 'package:flutter/gestures.dart';
import "package:flutter/material.dart";
import "package:timeline/colors.dart";

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            centerTitle: false,
            backgroundColor: lightGrey,
            iconTheme: IconThemeData(
                color: Colors.black.withOpacity(0.54)
            ),
            elevation: 0.0,
            title: Text(
                "About",
                style: TextStyle(
                    fontFamily: "RobotoMedium",
                    fontSize: 20.0,
                    color: darkText.withOpacity(darkText.opacity * 0.75)
                )
                ),
        ),
        body: Padding(
            padding: EdgeInsets.all(20.0),
            child:
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                [
                    Text(
                        "The History of\nEverything",
                        style: TextStyle(
                            fontFamily: "RobotoMedium",
                            fontSize: 34.0,
                            color: darkText.withOpacity(darkText.opacity * 0.75)
                        ),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(top: 17.0, bottom: 14.0),
                        child: Text(
                            "v1.0",
                            style: TextStyle(
                                fontFamily: "Roboto",
                                fontSize: 16.0,
                                height: 24.0/16.0,
                                color: darkText.withOpacity(darkText.opacity * 0.5)
                            ),
                        ),
                    ),
                    Expanded(
                        child: Column(
                            children: 
                            [
                                RichText(
                                    text: TextSpan(
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: "Roboto",
                                            fontSize: 16.0,
                                            height: 24.0/16.0
                                        ),
                                        children: 
                                        [
                                            TextSpan(
                                                text: "The History of Everything is built with ",
                                            ),
                                            TextSpan(
                                                text: "Flutter",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    decoration: TextDecoration.underline
                                                ),
                                                recognizer: TapGestureRecognizer()..onTap = (){} // TODO: open web page
                                            ),
                                            TextSpan(
                                                text: " by ",
                                            ),
                                            TextSpan(
                                                text: "2Dimensions",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    decoration: TextDecoration.underline
                                                ),
                                                recognizer: TapGestureRecognizer()..onTap = (){} // TODO: open web page 
                                            ),
                                            TextSpan(
                                                text: ". The graphics and animations were created using tools by ",
                                            ),
                                            TextSpan(
                                                text: "2Dimensions",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    decoration: TextDecoration.underline
                                                ),
                                                recognizer: TapGestureRecognizer()..onTap = (){} // TODO: open web page
                                            ),
                                            TextSpan(
                                                text: ".",
                                            )
                                        ]
                                    )
                                )
                            ]
                        )
                    ),
                    Text(
                        "Designed by",
                        style: TextStyle(
                                fontFamily: "Roboto",
                                fontSize: 16.0,
                                height: 28.0/16.0,
                                color: Colors.black.withOpacity(0.5)
                            ),
                    ),
                    Padding(
                        padding: EdgeInsets.only(top:10.0, bottom: 30.0),
                        child: Image.asset("assets/twoDimensions_logo.png", height: 20.0,)
                    ),
                    Text(
                        "Built with",
                        style: TextStyle(
                                fontFamily: "Roboto",
                                fontSize: 16.0,
                                height: 28.0/16.0,
                                color: Colors.black.withOpacity(0.5)
                            ),
                    ),
                    Padding(
                        padding: EdgeInsets.only(top:10.0, bottom: 20.0),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children:
                            [
                                Image.asset("assets/flutter_logo.png", height: 45.0, width: 37.0),
                                Container(
                                    margin: const EdgeInsets.only(left: 12.0),
                                    child: Text("Flutter",
                                        style: TextStyle(
                                                fontSize: 23.0,
                                                color: darkText.withOpacity(darkText.opacity * 0.85)
                                            ),
                                    ),
                                )
                            ]
                        )
                    ),
                ],
            ),
        )
    );
  }
}