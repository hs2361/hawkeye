import 'sign_in_form.dart';
import 'sign_up_form.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isSigningIn = false; //bool flag to switch between sign in and sign up
  void _showFormDialog(BuildContext context) {
    showDialog(
      context: context,
      child: AlertDialog(
        //dialog window for authentication forms
        titlePadding: EdgeInsets.fromLTRB(20, 20, 0, 0),
        contentPadding: EdgeInsets.symmetric(horizontal: 5),
        title: Text(isSigningIn ? 'Sign In' : 'Sign Up'),
        actionsPadding: EdgeInsets.only(right: 15, bottom: 5),
        content: isSigningIn ? SignInForm() : SignUpForm(),
        actions: <Widget>[
          GestureDetector(
            onTap: () {
              //auth mode switcher
              isSigningIn = !isSigningIn;
              Navigator.of(context).pop();
              _showFormDialog(context);
            },
            child: Text(
              isSigningIn ? 'Sign Up instead' : 'Sign In instead',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            FlatButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            )
          ],
        );
      },
    );
  }

  // @override
  // void initState() {
  //   bool _initialized = false;
  //   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  //   if (!_initialized) {
  //     // For iOS request permission first.
  //     _firebaseMessaging.requestNotificationPermissions();
  //     _firebaseMessaging.configure(
  //       onMessage: (Map<String, dynamic> message) async {
  //         print("violence detected");
  //         final dynamic data = message['data'] ?? message;
  //         print(data);
  //         HapticFeedback.vibrate();
  //       },
  //     );

  //     _firebaseMessaging.getToken().then((token) {
  //       print("FirebaseMessaging token: $token");
  //     });

  //     _initialized = true;
  //   }
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Spacer(),
          //auth screen title...
          Text(
            'Welcome to'.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyText1.color,
              fontSize: 18,
              fontFamily: 'Montserrat',
            ),
          ),
          RichText(
            textAlign: TextAlign.center,
            text: new TextSpan(children: <TextSpan>[
              new TextSpan(
                text: 'HAWK',
                style: TextStyle(
                    fontSize: 45,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w300,
                    color: Theme.of(context).textTheme.bodyText1.color),
              ),
              new TextSpan(
                text: 'EYE',
                style: TextStyle(
                  fontSize: 45,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).accentColor,
                ),
              ),
            ]),
          ),
          Spacer(),
          //auth functionality...
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              //Sign in with email button
              Container(
                width: MediaQuery.of(context).size.width * 0.6,
                child: RaisedButton(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  onPressed: () {
                    setState(() {
                      isSigningIn = true;
                    });
                    _showFormDialog(context);
                  },
                  color: Color(0xDEFFFFFF),
                  textColor: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.email),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Sign In / Sign Up',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            height: 80,
          )
        ],
      ),
    );
  }
}
