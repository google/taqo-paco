import 'package:flutter/material.dart';

import 'app_drawer.dart';

class TaqoScaffold extends StatelessWidget {
  String title;
  Widget body;

  TaqoScaffold({this.title, this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.indigo,
      ),
      drawer: TaqoAppDrawer(),
      body: body,
    );
  }
}
