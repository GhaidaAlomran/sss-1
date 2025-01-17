//import 'dart:html';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:instayum1/widget/pickers/user_image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthForm extends StatefulWidget {
  AuthForm(
    this.submitFn,
    this.isLoeading,
  );

  final void Function(
    String email,
    String username,
    String password,
    File image,
    bool isSignUp,
    bool isDefaultImage, // NEW
    BuildContext ctx,
  ) submitFn;
  final bool isLoeading;

  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = true;
  bool _isDefaultImage = false; // NEW

  var _userEmail = "";
  var _userName = "";
  var _userPassword = "";
  File _userImageFile;

  void _pickedImage(File image) {
    _userImageFile = image;
  }

  Future<bool> usernameCheck(String username) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return result.docs.isEmpty;
  }

  void _trySubmit() async {
    final valid = await usernameCheck(_userName);
    if (!valid) {
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text("The username is already exist"),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
    } else {
      final isValid = _formKey.currentState?.validate();
      FocusScope.of(context).unfocus();

      if (_userImageFile == null && _isSignUp) {
        _isDefaultImage =
            true; //  if user did not choose an image then the defalut image should appear ==NEW
        //   Scaffold.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text("Please pick an image"),
        //       backgroundColor: Theme.of(context).errorColor,
        //     ),
        //   );
        //   return;
      }
      if (isValid) {
        _formKey.currentState?.save();
        widget.submitFn(
          _userEmail.trim(), // trim here to delete any extar space at the end
          _userName.trim(),
          _userPassword.trim(),
          _userImageFile,
          _isSignUp,
          _isDefaultImage,

          context,
        );
      }
    }
  }

  bool isValidEmail(String email) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

    RegExp regExp = new RegExp(pattern);

    return regExp.hasMatch(email);
  }

  bool isValiedUsername(String username) {
    String pattern = r'^[A-Za-z0-9]+(?:[ _-][A-Za-z0-9]+)*$';

    RegExp regExp = new RegExp(pattern);

    return regExp.hasMatch(username);
  }

  bool isValiedPassword(String password) {
    String pattern =
        r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';

    RegExp regExp = new RegExp(pattern);

    return regExp.hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Center(
        child: Card(
          margin: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _isSignUp ? "Sign Up" : "Login",
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).accentColor),
                    ),
                    if (_isSignUp) UserImagePicker(_pickedImage),
                    TextFormField(
                      key: ValueKey(
                          "email"), // علشان اذا حولت من لوق ان الى ساين اب ما يتحول الوزرنيم الى باسوورد
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Email should not be empty";
                        } else if (!isValidEmail(value)) {
                          return "Please enter a valid email";
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _userEmail = value;
                      },
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: "Email address"),
                    ),
                    if (_isSignUp)
                      TextFormField(
                        key: ValueKey("username"),
                        validator: (value) {
                          if (value.isEmpty) {
                            return "username should not be empty";
                          } else if (!isValiedUsername(value) ||
                              value.length < 4) {
                            return "The username must contain at least 4 characters";
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _userName = value;
                        },
                        decoration: InputDecoration(labelText: "Username"),
                      ),
                    TextFormField(
                      key: ValueKey("password"),
                      validator: (value) {
                        if (value.isEmpty) {
                          return "password should not be empty";
                        } else if (!isValiedPassword(value)) {
                          return "The password must conatint at least \none upper case \none lower case \none digit \none special character \nand at least 8 characters in length";
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _userPassword = value;
                      },
                      decoration: InputDecoration(labelText: "Password"),
                      obscureText: true, // to hide the password
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    if (widget.isLoeading) CircularProgressIndicator(),
                    if (!widget.isLoeading)
                      RaisedButton(
                        child: Text(_isSignUp ? "Sign Up" : "Login"),
                        onPressed: _trySubmit,
                      ),
                    if (!widget.isLoeading)
                      FlatButton(
                          textColor: Color(
                              0xFFeb6d44), //Theme.of(context).primaryColor,
                          child: Text(_isSignUp
                              ? "Already I have an account"
                              : "Create a new account"),
                          onPressed: () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                            });
                          })
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
