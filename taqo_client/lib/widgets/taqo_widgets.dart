import 'package:flutter/material.dart';

const double _buttonRadius = 12;

class TaqoRoundButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double height;

  TaqoRoundButton({@required this.onPressed, this.child, this.height, });

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      height: height ?? 36,
      child: FlatButton(
        onPressed: onPressed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        color: Colors.indigo,
        textColor: Colors.white,
        child: child,
      ),
    );
  }
}

const double _cardPadding = 12;
const double _cardRadius = 8;

class TaqoCard extends StatelessWidget {
  final Widget child;

  TaqoCard({@required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(_cardPadding),
        child: child,
      ),
    );
  }
}
