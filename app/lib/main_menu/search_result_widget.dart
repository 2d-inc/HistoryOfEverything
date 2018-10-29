import "package:flutter/material.dart";
import "../colors.dart";

class SearchResultWidget extends StatelessWidget
{
    final String label, date, imagePath;

    SearchResultWidget(this.label, this.date, this.imagePath, {Key key}) : super(key:key);

    @override
    Widget build(BuildContext context)
    {
        // Use Material + InkWell to show a ripple effect on the row.
        return Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: () => print("TAP"),
                child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: 
                            [
                                CircleAvatar(
                                    radius: 17.0,
                                    backgroundImage: AssetImage(imagePath), 
                                ),
                                Container(
                                    margin: EdgeInsets.only(left: 17.0),  
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: 
                                        [
                                            Text(label,
                                                style: TextStyle(
                                                    fontFamily: "RobotoMedium",
                                                    fontSize: 20.0,
                                                    color: darkText.withOpacity(darkText.opacity*0.75)
                                                )
                                            ,),
                                            Text(date,
                                                style: TextStyle(
                                                    fontFamily: "Roboto",
                                                    fontSize: 14.0,
                                                    color: Colors.black.withOpacity(0.5)
                                                )
                                            )
                                        ]
                                    ),
                                )
                            ],
                        ),
                    ),
            )
        );
    }
}