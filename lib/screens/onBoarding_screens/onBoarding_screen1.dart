import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class onBoardingScreen1 extends StatelessWidget {
  const onBoardingScreen1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[100],
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_itqodaed.json'),
          Text("Welcome to Sniffer",
              style: GoogleFonts.bebasNeue(
                  fontSize: 40, color: Colors.deepPurple[500])),
        ],
      )),
    );
  }
}
