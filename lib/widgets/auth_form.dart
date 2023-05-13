import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthForm extends StatefulWidget {
  final bool isLoading;
  final Function(BuildContext context) forgotPasswordCallback;
  final void Function(
    String email,
    String password,
    String firstName,
    String lastName,
    bool isLogin,
    BuildContext ctx,
  ) submitFn;

  AuthForm(this.submitFn, this.isLoading, this.forgotPasswordCallback);

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  var _isLogin = true;
  String _userEmail = '';
  String _userPassword = '';
  String _userFirstName = '';
  String _userLastName = '';

  bool confirmPasswordMatch() {
    bool passwordRequirements(String password) {
      bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
      bool hasDigits = password.contains(RegExp(r'[0-9]'));
      bool hasLowercase = password.contains(RegExp(r'[a-z]'));
      bool hasSpecialCharacters =
          password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      bool hasMinLength = password.length >= 8;

      return hasDigits &
          hasUppercase &
          hasLowercase &
          hasSpecialCharacters &
          hasMinLength;
    }

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text.trim() ==
            _confirmpasswordController.text.trim()) {
      if (passwordRequirements(_passwordController.text.trim())) {
        return true;
      }
    }

    return false;
  }

  void _trySubmit() {
    final isValid = formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    _userEmail = _emailController.text;
    _userPassword = _passwordController.text;
    _userFirstName = _firstnameController.text;
    _userLastName = _lastnameController.text;

    if (isValid) {
      formKey.currentState!.save();
      widget.submitFn(
        _userEmail.trim(),
        _userPassword.trim(),
        _userFirstName.trim(),
        _userLastName.trim(),
        _isLogin,
        context,
      );
      //send to firebase to auth
    }
  }

  @override
  Widget build(BuildContext context) {
    String welcomeMessage1 = _isLogin ? 'HELLO AGAIN!' : 'HELLO THERE';
    String welcomeMessage2 =
        _isLogin ? 'Your pet missed you!' : 'Never lose your pet again.';

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Text(welcomeMessage1,
                      style: GoogleFonts.bebasNeue(fontSize: 50)),
                  SizedBox(
                    height: 10,
                  ),
                  Text(welcomeMessage2,
                      style: GoogleFonts.openSans(fontSize: 26)),
                  SizedBox(
                    height: 20,
                  ),
                  if (!_isLogin)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25.0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: TextFormField(
                            key: ValueKey('firstname'),
                            controller: _firstnameController,
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'First name'),
                            validator: (value) {
                              if (value!.isEmpty ||
                                  !RegExp(r'^[a-z A-Z]+$').hasMatch(value)) {
                                return 'Enter a correct name';
                              } else
                                return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  if (!_isLogin)
                    SizedBox(
                      height: 20,
                    ),
                  if (!_isLogin)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: TextFormField(
                            key: ValueKey('lastname'),
                            controller: _lastnameController,
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Last name'),
                            validator: (value) {
                              if (value!.isEmpty ||
                                  !RegExp(r'^[a-z A-Z]+$').hasMatch(value)) {
                                return 'Enter a correct name';
                              } else
                                return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: TextFormField(
                          key: ValueKey('email'),
                          controller: _emailController,
                          decoration: InputDecoration(
                              border: InputBorder.none, hintText: 'Email'),
                          validator: (value) {
                            if (!_isLogin) {
                              if (value!.isEmpty ||
                                  !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                                      .hasMatch(value)) {
                                return 'Enter a valid email address';
                              } else
                                return null;
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  /*Password*/
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: TextFormField(
                          key: ValueKey('password'),
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                              border: InputBorder.none, hintText: 'Password'),
                          validator: (value) {
                            if (!_isLogin) {
                              if (value!.isEmpty) {
                                return 'Please enter a password';
                              } else if (!_isLogin && !confirmPasswordMatch()) {
                                return 'Password does not meet requirements';
                              }
                              return null;
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                  if (!_isLogin)
                    SizedBox(
                      height: 20,
                    ),
                  if (!_isLogin)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: TextFormField(
                            key: ValueKey('confirmpassword'),
                            controller: _confirmpasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Confirm Password'),
                            validator: (value) {
                              if (!_isLogin) {
                                if (value!.isEmpty || !confirmPasswordMatch()) {
                                  return 'Passwords do not match';
                                } else
                                  return null;
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 20,
                  ),
                  if (widget.isLoading) CircularProgressIndicator(),
                  if (!widget.isLoading)
                    /*Sign up button*/
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: GestureDetector(
                        onTap: () {
                          if (formKey.currentState!.validate()) {
                            _trySubmit();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(60)),
                          child: Center(
                            child: Text(
                              !_isLogin ? 'Sign Up' : 'Sign In',
                              style: GoogleFonts.openSans(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isLogin ? 'Not a member? ' : 'Already a member ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          !_isLogin ? 'Login now' : 'Register now',
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  if (_isLogin)
                    TextButton(
                      onPressed: () {
                        widget.forgotPasswordCallback(context);
                      },
                      child: Text('Forgot Password?',
                        style: TextStyle(color: Colors.deepPurple),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
