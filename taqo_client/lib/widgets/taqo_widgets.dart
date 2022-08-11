// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// @dart=2.9

import 'package:flutter/material.dart';

const double _buttonRadius = 12;

class TaqoRoundButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double height;

  TaqoRoundButton({
    @required this.onPressed,
    this.child,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      height: height ?? 36,
      child: FlatButton(
        onPressed: onPressed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        child: child,
        color: Colors.indigo,
        textColor: Colors.white,
        disabledColor: Colors.indigo.withOpacity(.6),
        disabledTextColor: Colors.white.withOpacity(.8),
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


class TaqoTextField extends StatefulWidget {
  const TaqoTextField({Key key,ValueChanged<String> onChanged, });
  @override
  State<TaqoTextField> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
}
class _TaqoTextFieldState extends State<TaqoTextField> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}