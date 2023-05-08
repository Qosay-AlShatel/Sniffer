import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class onBoardingScreen2 extends StatelessWidget {
  static const routeName = '/onBoardingScreen2';

  const onBoardingScreen2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[300],
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_Q1pZ8v.json'),
          Text("Never lose your pet again!",
              style: GoogleFonts.bebasNeue(fontSize: 30, color: Colors.white)),
        ],
      )),
    );
  }
}
