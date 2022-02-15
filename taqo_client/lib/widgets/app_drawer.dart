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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../pages/find_experiments_page.dart';
import '../pages/login_page.dart';
import '../pages/running_experiments_page.dart';
import '../providers/auth_provider.dart';
import '../main.dart';

class TaqoAppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
      ],
      child: _TaqoAppDrawerWidget(),
    );
  }
}

const double _listIconSize = 36;

class _TaqoAppDrawerWidget extends StatelessWidget {
  Widget _profilePictureWidget(AuthProvider authProvider) {
    const double size = 96;
    if (authProvider.userInfoPhoto != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            fit: BoxFit.fill,
            image: CachedNetworkImageProvider(authProvider.userInfoPhoto),
          ),
        ),
      );
    } else {
      return Icon(
        Icons.account_circle,
        color: Colors.indigo.shade800,
        size: size,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Added for bug #72
    final ThemeData theme = Theme.of(context);

    final TextStyle textStyle = theme.textTheme.bodyText2;
    final List<Widget> aboutTaqoWidget = <Widget>[
      const SizedBox(height: 24),
      RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
                style: textStyle,
                text: "Taqo is made possible by Flutter and many other open "
                    "source software/libraries. Click “VIEW LICENSES” for "
                    "more details."),
          ],
        ),
      ),
    ];

    // End of add for bug #72
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.indigo),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: _profilePictureWidget(authProvider),
                  ),
                  Text(
                    authProvider.userInfoName ?? '',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.person_add,
              size: _listIconSize,
            ),
            title: const Text('Login or Join with Code'),
            onTap: () =>
                MyApp.navigatorKey.currentState.pushNamed(LoginPage.routeName),
          ),
          ListTile(
            leading: Icon(
              Icons.assignment,
              size: _listIconSize,
            ),
            title: const Text('My Experiments'),
            onTap: () => MyApp.navigatorKey.currentState
                .pushNamed(RunningExperimentsPage.routeName),
            enabled: authProvider.isAuthenticated,
          ),
          ListTile(
            leading: Icon(
              Icons.search,
              size: _listIconSize,
            ),
            title: const Text('Find New Experiments'),
            onTap: () => MyApp.navigatorKey.currentState
                .pushNamed(FindExperimentsPage.routeName),
            enabled: authProvider.isAuthenticated,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(),
          ),
          ListTile(
            leading: Icon(
              Icons.exit_to_app,
              size: _listIconSize,
            ),
            title: const Text('Logout'),
            onTap: () {
              authProvider.signOut();
            },
            enabled: authProvider.isAuthenticated,
          ),

          // Added for bug #72
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(),
          ),
          //AssetImage('assets/sentiment_very_dissatisfied.png'),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              size: _listIconSize,
            ),
            title: const Text('About Taqo'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationIcon:  Image.asset('assets/paco256.png', scale: 10,),
                applicationName: 'About Taqo',
                applicationLegalese: 'Copyright 2022 Google LLC',
                children: aboutTaqoWidget,
              );
            },
          ),
          // End of add for bug #72

        ],
      ),
    );
  }
}
