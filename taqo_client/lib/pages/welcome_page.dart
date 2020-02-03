import 'package:flutter/material.dart';
import 'package:taqo_client/net/google_auth.dart';
import 'package:taqo_client/pages/running_experiments_page.dart';
import 'package:taqo_client/service/experiment_service.dart';
import 'package:taqo_client/storage/joined_experiments_storage.dart';
import 'package:taqo_client/storage/unsecure_token_storage.dart';

import 'find_experiments_page.dart';
import 'invitation_entry_page.dart';
import 'login_page.dart';

// Entry page for App
class WelcomePage extends StatefulWidget {
  static const routeName = '/welcome';

  WelcomePage({Key key}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  var _authenticated = false;

  GoogleAuth gAuth = GoogleAuth();
  var authListener;

  var experimentService = ExperimentService();

  _WelcomePageState();

  @override
  void initState() {
    super.initState();
    gAuth.isAuthenticated().then((res) {
      setState(() {
        _authenticated = res;
      });
    });
    authListener = gAuth.onAuthChanged.listen((newAuthState) {
      setState(() {
        _authenticated = newAuthState;
      });
    });
  }

  @override
  void dispose() {
    authListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Taqo - Welcome'),
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        padding: EdgeInsets.all(8.0),
        //margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        child: ListView(
          padding: EdgeInsets.all(4.0),
          children: <Widget>[
            buildWelcomeTextWidget(),
            Divider(
              height: 16.0,
              color: Colors.black,
            ),
            buildLoginButtonWidget(context),
            buildInvitationButtonWidget(context),
            buildLogoutButtonWidget(context),
            //Divider(),
            buildFindExperimentsButtonWidget(context),
            buildRunningExperimentsButtonWidget(context),
            //Divider(),
          ],
        ),
      ),
    );
  }

  Text buildWelcomeTextWidget() {
    return Text(
      'Welcome!\n\nTaqo/Paco is a behavior research platform.\n\nTo get started, please either login with a Google account or enter an invitation code if you have one.',
    );
  }

  RaisedButton buildLoginButtonWidget(BuildContext context) {
    return RaisedButton(
      onPressed: _authenticated
          ? null
          : () {
              Navigator.pushReplacementNamed(context, LoginPage.routeName);
            },
      child: const Text('Login with Google Id'),
    );
  }

  void _logout(BuildContext context) async {
    await ExperimentService().clear();
    gAuth.clearCredentials();

    // Clear navigation stack. Navigator doesn't allow clearing the stack without pushing,
    // so we're using PageRouteBuilder to disable the animation/transition since we're staying
    // on WelcomePage
    Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(pageBuilder: (context, _, __) => WelcomePage()),
        (route) => false,
    );

    setState(() => _authenticated = false);
  }

  RaisedButton buildLogoutButtonWidget(BuildContext context) {
    return RaisedButton(
      onPressed: _authenticated ? () => _logout(context) : null,
      child: const Text('Logout'),
    );
  }

  RaisedButton buildInvitationButtonWidget(BuildContext context) {
    return RaisedButton(
      onPressed: _authenticated
          ? null
          : () {
              Navigator.pushReplacementNamed(
                  context, InvitationEntryPage.routeName);
            },
      child: const Text('Enter Invitation Code'),
    );
  }

  RaisedButton buildFindExperimentsButtonWidget(BuildContext context) {
    return RaisedButton(
      onPressed: !_authenticated
          ? null
          : () {
              Navigator.pushReplacementNamed(
                  context, FindExperimentsPage.routeName);
            },
      child: const Text('Find Experiments to Join'),
    );
  }

  StreamBuilder buildRunningExperimentsButtonWidget(BuildContext context) {
    return StreamBuilder(
        stream: experimentService.onJoinedExperimentsLoaded,
        builder: (context, snapshot) => RaisedButton(
              onPressed: isAlreadyRunningExperiments()
                  ? () {
                      Navigator.pushReplacementNamed(
                          context, RunningExperimentsPage.routeName);
                    }
                  : null,
              child: const Text('Go to Joined Experiments'),
            ));
  }

  bool isAlreadyRunningExperiments() =>
      _authenticated && ExperimentService().getJoinedExperiments().isNotEmpty;
}
