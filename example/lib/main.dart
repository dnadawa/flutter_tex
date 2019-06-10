import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

import 'teXHTML.dart';

main() async {
  runApp(FlutterTeX());
}

class FlutterTeX extends StatefulWidget {
  @override
  _FlutterTeXState createState() => _FlutterTeXState();
}

class _FlutterTeXState extends State<FlutterTeX> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Flutter TeX Example"),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  setState(() {});
                })
          ],
        ),

        body: ListView(
          children: <Widget>[


            TeXView(
              // any random unique index (0-9) is mandatory if you are using multiple TeXView in a List view on same page.
            index: 0,
              teXHTML: teXHTML,
              onRenderFinished: (height) {
                print("Height is : $height");
              },
              onPageFinished: (string){
                print("Page Loading finished");

              },
            ),
            TeXView(
              // any random unique index (0-9) is mandatory if you are using multiple TeXView in a List view on a same page.
              index: 1,
              teXHTML: teXHTML,
            ),            TeXView(
              // any random unique index (0-9) is mandatory if you are using multiple TeXView in a List view on a same page.
              index: 2,
              teXHTML: teXHTML,
            )
          ],
        ),
      ),
    );
  }
}
