import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'http_exception.dart';

//Auth Provider
class Auth with ChangeNotifier {
  IdTokenResult _token;
  DateTime _expiryDate;
  String _userId;
  Timer _authTimer;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //getter for token data, returns _token
  IdTokenResult get token {
    if (_token != null &&
        _expiryDate != null &&
        _expiryDate.isAfter(DateTime.now())) return _token;
    return null;
  }

  //getter for organization name
  Future<String> get organization async {
    var user = _auth.currentUser;
    notifyListeners();
    return user != null ? user.displayName : '';
  }

  Future<String> get email async {
    var user = _auth.currentUser;
    notifyListeners();
    return user != null ? user.email : "";
  }

  //getter for isAuth bool flag. Utilises currentUser() method to obtain data and refresh user's token simultaneously
  Future<bool> get isAuth async {
    var user = _auth.currentUser;
    if (user != null) {
      _token = await user.getIdTokenResult();
      _expiryDate = _token.expirationTime;
      _userId = user.uid;
      notifyListeners();
    }
    return user != null && user.emailVerified;
  }

  //getter for userId. Also utilises currentUser()
  Future<String> get userId async {
    if (_userId == null) {
      var res = _auth.currentUser;
      return res.uid;
    }
    return _userId;
  }

  //general method to authenticate (sign up + sign in) user using email + password
  //uses mode parameter to switch between sign in and sign up
  Future<bool> _authenticateWithEmail(
    String organization,
    String mode,
    String email,
    String password,
  ) async {
    UserCredential res;
    try {
      if (mode == 'signup') {
        res = (await _auth.createUserWithEmailAndPassword(
          //firebase package method
          email: email,
          password: password,
        ));
        await res.user.sendEmailVerification();
      } else {
        res = await _auth.signInWithEmailAndPassword(
            //firebase package method
            email: email,
            password: password);
        if (!res.user.emailVerified) {
          await res.user.sendEmailVerification();
        }
      }
      User user = res.user;
      _userId = user.uid;
      _token = await user.getIdTokenResult(); //obtain user's token data
      _expiryDate = _token.expirationTime; //obtain token expiry date
      final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
      print("Organization ID ${user.displayName}");
      _firebaseMessaging.subscribeToTopic(user.displayName);
      if (mode == 'signup') {
        user.updateProfile(displayName: organization);
      }
    } catch (error) {
      throw error;
    }

    _autoLogout(); //autologout method called to start logout timer based on token expiry date
    notifyListeners();
    return res.user.emailVerified;
  }

  //method to sign up user with email
  Future<void> signupWithEmail(
    String organization,
    String email,
    String password,
  ) async {
    await _authenticateWithEmail(organization, 'signup', email, password);
  }

  //method to sign in user with email
  Future<bool> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _authenticateWithEmail('', 'login', email, password);
    } catch (error) {
      throw HttpException(error.code);
    }
  }

  //method to logout user
  Future<void> logout() async {
    _token = null;
    _expiryDate = null;
    if (_authTimer != null) {
      _authTimer.cancel();
      _authTimer = null;
    }
    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }

  //method to auto-logout user on token expiration (in case token is not refreshed)
  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer.cancel();
    }
    final timeToExpiry = _expiryDate.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }
}
