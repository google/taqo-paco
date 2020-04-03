import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/taqo_page.dart';
import 'invitation_entry_page.dart';

class LoginPage extends StatelessWidget {
  static const routeName = 'login';

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildCloneableWidget>[
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
      ],
      child: _LoginPageWidget(),
    );
  }
}

class _LoginPageWidget extends StatelessWidget {
  Text buildWelcomeTextWidget() {
    return const Text("""
Welcome!

Taqo/Paco is a behavior research platform.

To get started, please either login with a Google account or enter an invitation code if you have one.""");
  }

  RaisedButton buildLoginButtonWidget(BuildContext context,
      AuthProvider authProvider, bool isAuthenticated) {
    return RaisedButton(
      onPressed: isAuthenticated ? null : () {
        authProvider.signIn();
      },
      child: const Text('Login with Google Id'),
    );
  }

  RaisedButton buildInvitationButtonWidget(BuildContext context, bool isAuthenticated) {
    return RaisedButton(
      onPressed: isAuthenticated ? null : () {
        Navigator.pushNamed(context, InvitationEntryPage.routeName);
      },
      child: const Text('Enter Invitation Code'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return TaqoScaffold(
      title: 'Login',
      body: Container(
        padding: EdgeInsets.all(8.0),
        child: ListView(
          padding: EdgeInsets.all(4.0),
          children: <Widget>[
            buildWelcomeTextWidget(),
            Divider(
              height: 16.0,
              color: Colors.black,
            ),
            buildLoginButtonWidget(context, authProvider,
                authProvider.isAuthenticated),
            buildInvitationButtonWidget(context, authProvider.isAuthenticated),
          ],
        ),
      ),
    );
  }
}
