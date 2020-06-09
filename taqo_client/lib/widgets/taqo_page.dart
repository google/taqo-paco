import 'package:flutter/material.dart';

import 'app_drawer.dart';

class TaqoScaffold extends StatelessWidget {
  String title;
  Widget body;
  List<Widget> actions;

  TaqoScaffold({
    this.title,
    this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.indigo,
        actions: actions,
      ),
      drawer: TaqoAppDrawer(),
      body: body,
    );
  }
}
