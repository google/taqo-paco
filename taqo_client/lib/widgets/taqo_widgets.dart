import 'package:flutter/material.dart';

const double _borderRadius = 12;

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
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        color: Colors.indigo,
        textColor: Colors.white,
        child: child,
      ),
    );
  }
}
